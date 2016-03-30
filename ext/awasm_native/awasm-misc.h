#pragma once

#include "awasm-error.h"

#define _AWASM_DOMAIN_HEADER \
  awasm_domain_type type: 8; \
  unsigned index         :24;

#define _AWASM_ENUM_HEADER \
  _AWASM_DOMAIN_HEADER \
  uint16_t len;

#define _AWASM_DECL_ENUM_TYPE(l) \
  typedef struct { \
    _AWASM_ENUM_HEADER \
    int64_t vals[l]; \
  } awasm_enum ## l;


#define AWASM_ENUM_MAX_LEN 32

#define AWASM_ENUM_VALS_SIZE(len) ((size_t)(len) * sizeof(int64_t))
#define AWASM_ENUM_SIZE(len) (sizeof(awasm_enum) + AWASM_ENUM_VALS_SIZE(len))

typedef enum {
  AWASM_DOMAIN_TYPE_ENUM,
  AWASM_DOMAIN_TYPE_INTERVAL,
  AWASM_DOMAIN_TYPE_INTERVAL64,
  AWASM_N_DOMAIN_TYPES
} awasm_domain_type;

typedef struct {
  _AWASM_DOMAIN_HEADER
  int64_t pad[AWASM_ENUM_MAX_LEN];
} awasm_domain;

typedef struct {
  _AWASM_DOMAIN_HEADER
  int64_t min;
  int64_t max;
} awasm_interval;

typedef struct {
  _AWASM_ENUM_HEADER
  int64_t vals[];
} awasm_enum;

_AWASM_DECL_ENUM_TYPE(2)
_AWASM_DECL_ENUM_TYPE(3)
_AWASM_DECL_ENUM_TYPE(4)
_AWASM_DECL_ENUM_TYPE(8)
_AWASM_DECL_ENUM_TYPE(11)
_AWASM_DECL_ENUM_TYPE(16)

typedef struct {
  uint64_t data[16];
} awasm_prng64_seed;

typedef struct {
  uint32_t data[4];
} awasm_prng32_seed;

typedef struct awasm_prng64 {
  /* xorshift1024star */
  awasm_prng64_seed s;
  int p;
} awasm_prng64;

typedef struct awasm_prng32 {
  /* xorshift128 */
  awasm_prng32_seed s;
  int p;
} awasm_prng32;

void
awasm_prng64_init(struct awasm_prng64 *prng, awasm_prng64_seed *seed);

void
awasm_prng64_destroy(struct awasm_prng64 *prng);

void
awasm_prng32_init(struct awasm_prng32 *prng, awasm_prng32_seed *seed);

void
awasm_prng32_destroy(struct awasm_prng32 *prng);

/* From: https://en.wikipedia.org/wiki/Xorshift */
static inline uint64_t
awasm_prng64_rand(struct awasm_prng64 *prng) {
  uint64_t *s = prng->s.data;
  const uint64_t s0 = s[prng->p];
  uint64_t s1 = s[prng->p = (prng->p + 1) & 15];
  s1 ^= s1 << 31; // a
  s[prng->p] = s1 ^ s0 ^ (s1 >> 11) ^ (s0 >> 30); // b,c
  return s[prng->p] * UINT64_C(1181783497276652981);
}

static inline uint32_t
awasm_prng32_rand(struct awasm_prng32 *prng) {
  uint32_t *s = prng->s.data;
  uint32_t t = s[0];
  t ^= t << 11;
  t ^= t >> 8;
  s[0] = s[1]; s[1] = s[2]; s[2] = s[3];
  s[3] ^= s[3] >> 19;
  s[3] ^= t;
  return s[3];
}

static inline int64_t
awasm_prng64_rand_between(struct awasm_prng64 *prng, int64_t min, int64_t max) {
  return min + (int64_t)(awasm_prng64_rand(prng) % (uint64_t)(max - min + 1ll));
}

static inline int32_t
awasm_prng32_rand_between(struct awasm_prng32 *prng, int32_t min, int32_t max) {
  return min + (int32_t)(awasm_prng32_rand(prng) % (uint32_t)(max - min + 1ll));
}

static inline int64_t
awasm_domain_rand(awasm_domain *domain, struct awasm_prng64 *prng) {
  switch(domain->type) {
    case AWASM_DOMAIN_TYPE_INTERVAL: {
      awasm_interval *interval = (awasm_interval *) domain;
      return awasm_prng64_rand_between(prng, interval->min, interval->max);
    }
    case AWASM_DOMAIN_TYPE_INTERVAL64: {
      return (int64_t) awasm_prng64_rand(prng);
    }
    case AWASM_DOMAIN_TYPE_ENUM: {
      awasm_enum *enm = (awasm_enum *) domain;
      return enm->vals[awasm_prng64_rand(prng) % enm->len];
    }
    default:
      awasm_assert_not_reached();
      return 0;
  }
}

static inline size_t
awasm_domain_size(awasm_domain *domain) {
  switch(domain->type){
    case AWASM_DOMAIN_TYPE_INTERVAL:
    case AWASM_DOMAIN_TYPE_INTERVAL64: return sizeof(awasm_interval);
    case AWASM_DOMAIN_TYPE_ENUM: return AWASM_ENUM_SIZE(((awasm_enum *) domain)->len);
    default:
      awasm_assert_not_reached();
      return 0;
  }
}

static inline void
awasm_domain_clone(awasm_domain * restrict domain, awasm_domain * restrict domain_dst) {
  domain_dst->type = domain->type;

  switch(domain->type) {
    case AWASM_DOMAIN_TYPE_INTERVAL:
    case AWASM_DOMAIN_TYPE_INTERVAL64: {
      awasm_interval *interval = (awasm_interval *) domain;
      awasm_interval *interval_dst = (awasm_interval *) domain_dst;
      interval_dst->min = interval->min;
      interval_dst->max = interval->max;
      break;
    }
    case AWASM_DOMAIN_TYPE_ENUM: {
      awasm_enum *enm = (awasm_enum *) domain;
      awasm_enum *enm_dst = (awasm_enum *) domain_dst;
      enm_dst->len = enm->len;
      memcpy(enm_dst->vals, enm->vals, AWASM_ENUM_VALS_SIZE(enm->len));
      break;
    }
    default: awasm_assert_not_reached();
  }
}


static inline void
awasm_domain_intersect(awasm_domain * restrict domain1, awasm_domain * restrict domain2, awasm_domain * restrict domain_dst) {

#define _AWASM_DOMAIN_TYPES2(type_a, type_b) (int)(((type_a) << 8) | (type_b))

  switch(_AWASM_DOMAIN_TYPES2(domain1->type, domain2->type)) {
    case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_INTERVAL, AWASM_DOMAIN_TYPE_INTERVAL64):
    case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_INTERVAL, AWASM_DOMAIN_TYPE_INTERVAL):
    case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_INTERVAL64, AWASM_DOMAIN_TYPE_INTERVAL64):
    case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_INTERVAL64, AWASM_DOMAIN_TYPE_INTERVAL): {
      awasm_interval *interval1 = (awasm_interval *) domain1;
      awasm_interval *interval2 = (awasm_interval *) domain2;
      awasm_interval *interval_dst = (awasm_interval *) domain_dst;

      interval_dst->min = AWASM_MAX(interval1->min, interval2->min);
      interval_dst->max = AWASM_MIN(interval1->max, interval2->max);
      break;
    }
    case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_ENUM, AWASM_DOMAIN_TYPE_ENUM): {
      unsigned i = 0, j = 0;
      awasm_enum *enum1 = (awasm_enum *) domain1;
      awasm_enum *enum2 = (awasm_enum *) domain2;
      awasm_enum *enum_dst = (awasm_enum *) domain_dst;

      enum_dst->len = 0;
      /*
       * NOTE: vals are sorted (INC)
       */

      while(i < enum1->len && j < enum2->len) {
        int64_t v1 = enum1->vals[i];
        int64_t v2 = enum2->vals[j];

        if(v1 < v2) {
          i++;
        }
        else if(v2 < v2) {
          j++;
        }
        else {
          enum_dst->vals[enum_dst->len++] = v1;
          i++;
          j++;
        }
      }
      break;
    }
    {
      awasm_enum *enm;
      awasm_interval *interval;
      awasm_enum *enum_dst = (awasm_enum *) domain_dst;
      unsigned i;

      enum_dst->len = 0;

      case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_ENUM, AWASM_DOMAIN_TYPE_INTERVAL):
      case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_ENUM, AWASM_DOMAIN_TYPE_INTERVAL64):
        enm = (awasm_enum *) domain1;
        interval = (awasm_interval *) domain2;
        goto intersect;
      case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_INTERVAL, AWASM_DOMAIN_TYPE_ENUM):
      case _AWASM_DOMAIN_TYPES2(AWASM_DOMAIN_TYPE_INTERVAL64, AWASM_DOMAIN_TYPE_ENUM):
        enm = (awasm_enum *) domain2;
        interval = (awasm_interval *) domain1;
    intersect:
        for(i = 0; i < enm->len; i++) {
          if(enm->vals[i] >= interval->min && enm->vals[i] <= interval->max) {
            enum_dst->vals[enum_dst->len++] = enm->vals[i];
          }
        }
        break;
    }
    default:
      awasm_assert_not_reached();
  }

#undef _AWASM_DOMAIN_TYPES2
}

static inline bool
awasm_domain_contains_p(awasm_domain *domain, int64_t val) {
  switch(domain->type) {
    case AWASM_DOMAIN_TYPE_INTERVAL: {
      awasm_interval *interval = (awasm_interval *) domain;
      return val >= interval->min && val <= interval->max;
    }
    case AWASM_DOMAIN_TYPE_ENUM: {
      unsigned i;
      awasm_enum *enm = (awasm_enum *) domain;
      for(i = 0; i < enm->len; i++) {
        if(enm->vals[i] == val) return true;
      }
      return false;
    }
    default:
      awasm_assert_not_reached();
      return false;
  }
}

static inline int64_t
awasm_log2(int64_t num) {
  uint64_t log = 0;
  while (num >>= 1) ++log;
  return (int64_t)log;
}
