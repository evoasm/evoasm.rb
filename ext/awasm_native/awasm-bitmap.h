#pragma once

#include <stdint.h>
#include <stdbool.h>

#define _AWASM_BITMAP_INDEX_DECLS(key) \
  unsigned size = sizeof(uint64_t) * 8;\
  unsigned ary_idx = ((unsigned) key) / size;\
  unsigned bit_idx = ((unsigned) key) % size;

typedef struct {
  uint64_t data[1];
} awasm_bitmap64;

typedef struct {
  uint64_t data[2];
} awasm_bitmap128;

typedef struct {
  uint64_t data[4];
} awasm_bitmap256;

typedef struct {
  uint64_t data[8];
} awasm_bitmap512;

typedef uint64_t awasm_bitmap;

static inline void
awasm_bitmap_set(awasm_bitmap *bitmap, unsigned idx) {
  _AWASM_BITMAP_INDEX_DECLS(idx);
  bitmap[ary_idx] |= (1ull << bit_idx);
}

static inline void
awasm_bitmap_unset(awasm_bitmap *bitmap, unsigned idx) {
  _AWASM_BITMAP_INDEX_DECLS(idx);
  /* unset values must be 0*/
  bitmap[ary_idx] &= ~(1ull << bit_idx);
}

static inline bool
awasm_bitmap_get(awasm_bitmap *bitmap, unsigned idx) {
  _AWASM_BITMAP_INDEX_DECLS(idx);
  return !!(bitmap[ary_idx] & (1ull << bit_idx));
}


#define _AWASM_BITMAP_DECL_UNOP(name, width, op) \
  static inline void awasm_bitmap ## width ## _ ## name (awasm_bitmap##width *bitmap, awasm_bitmap##width *result) { \
    unsigned i;\
    for(i = 0; i < width / 64; i++) {\
      result->data[i] = op bitmap->data[i];\
    }\
  }

#define _AWASM_BITMAP_DECL_BINOP(name, width, op) \
  static inline void awasm_bitmap ## width ## _ ## name (awasm_bitmap##width *bitmap1, awasm_bitmap##width *bitmap2, awasm_bitmap##width *result) { \
    unsigned i;\
    for(i = 0; i < width / 64; i++) {\
      result->data[i] = bitmap1->data[i] op bitmap2->data[i];\
    }\
  }

#ifdef __GNUC__
#  define _AWASM_BITMAP_DECL_POPCOUNT(width) \
    static inline unsigned awasm_bitmap ## width ## _ ## popcount (awasm_bitmap##width *bitmap) { \
      unsigned c = 0, i;\
      for(i = 0; i < width / 64; i++) {\
        c += (unsigned) __builtin_popcountll(bitmap->data[i]);\
      } \
      return c;\
    }
#else
#  define _AWASM_BITMAP_DECL_POPCOUNT(width) \
    static inline unsigned awasm_bitmap ## width ## _ ## popcount (awasm_bitmap##width *bitmap) { \
      unsigned c = 0, i;\
      for(i = 0; i < width / 64; i++) {\
        uint64_t x = bitmap->data[i]; \
        for(; x > 0; x &= x - 1) c++;\
      } \
      return c;\
    }
#endif

_AWASM_BITMAP_DECL_UNOP(not, 128, ~)
_AWASM_BITMAP_DECL_BINOP(and, 128, &)
_AWASM_BITMAP_DECL_BINOP(or, 128, |)
_AWASM_BITMAP_DECL_BINOP(andn, 128, &~)
_AWASM_BITMAP_DECL_POPCOUNT(128)

_AWASM_BITMAP_DECL_UNOP(not, 64, ~)
_AWASM_BITMAP_DECL_BINOP(and, 64, &)
_AWASM_BITMAP_DECL_BINOP(or, 64, |)
_AWASM_BITMAP_DECL_POPCOUNT(64)
