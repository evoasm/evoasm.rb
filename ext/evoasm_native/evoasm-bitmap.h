#pragma once

#include <stdint.h>
#include <stdbool.h>

#define _EVOASM_BITMAP_INDEX_DECLS(key) \
  unsigned size = sizeof(uint64_t) * 8;\
  unsigned ary_idx = ((unsigned) key) / size;\
  unsigned bit_idx = ((unsigned) key) % size;

typedef struct {
  uint64_t data[1];
} evoasm_bitmap64;

typedef struct {
  uint64_t data[2];
} evoasm_bitmap128;

typedef struct {
  uint64_t data[4];
} evoasm_bitmap256;

typedef struct {
  uint64_t data[8];
} evoasm_bitmap512;

typedef struct {
  uint64_t data[16];
} evoasm_bitmap1024;


typedef uint64_t evoasm_bitmap;

static inline void
evoasm_bitmap_set(evoasm_bitmap *bitmap, unsigned idx) {
  _EVOASM_BITMAP_INDEX_DECLS(idx);
  bitmap[ary_idx] |= (1ull << bit_idx);
}

static inline void
evoasm_bitmap_unset(evoasm_bitmap *bitmap, unsigned idx) {
  _EVOASM_BITMAP_INDEX_DECLS(idx);
  /* unset values must be 0*/
  bitmap[ary_idx] &= ~(1ull << bit_idx);
}

static inline bool
evoasm_bitmap_get(evoasm_bitmap *bitmap, unsigned idx) {
  _EVOASM_BITMAP_INDEX_DECLS(idx);
  return !!(bitmap[ary_idx] & (1ull << bit_idx));
}


#define _EVOASM_BITMAP_DECL_UNOP(name, width, op) \
  static inline void evoasm_bitmap ## width ## _ ## name (evoasm_bitmap##width *bitmap, evoasm_bitmap##width *result) { \
    unsigned i;\
    for(i = 0; i < width / 64; i++) {\
      result->data[i] = op bitmap->data[i];\
    }\
  }

#define _EVOASM_BITMAP_DECL_BINOP(name, width, op) \
  static inline void evoasm_bitmap ## width ## _ ## name (evoasm_bitmap##width *bitmap1, evoasm_bitmap##width *bitmap2, evoasm_bitmap##width *result) { \
    unsigned i;\
    for(i = 0; i < width / 64; i++) {\
      result->data[i] = bitmap1->data[i] op bitmap2->data[i];\
    }\
  }

#define _EVOASM_BITMAP_DECL_EQL(width) \
  static inline bool evoasm_bitmap ## width ## _ ## eql (evoasm_bitmap##width *bitmap1, evoasm_bitmap##width *bitmap2) { \
    unsigned i;\
    for(i = 0; i < width / 64; i++) {\
      if(bitmap1->data[i] != bitmap2->data[i]) return false;\
    } \
    return true;\
  }


#ifdef __GNUC__
#  define _EVOASM_BITMAP_DECL_POPCOUNT(width) \
    static inline unsigned evoasm_bitmap ## width ## _ ## popcount (evoasm_bitmap##width *bitmap) { \
      unsigned c = 0, i;\
      for(i = 0; i < width / 64; i++) {\
        c += (unsigned) __builtin_popcountll(bitmap->data[i]);\
      } \
      return c;\
    }
#else
#  define _EVOASM_BITMAP_DECL_POPCOUNT(width) \
    static inline unsigned evoasm_bitmap ## width ## _ ## popcount (evoasm_bitmap##width *bitmap) { \
      unsigned c = 0, i;\
      for(i = 0; i < width / 64; i++) {\
        uint64_t x = bitmap->data[i]; \
        for(; x > 0; x &= x - 1) c++;\
      } \
      return c;\
    }
#endif

_EVOASM_BITMAP_DECL_UNOP(not, 128, ~)
_EVOASM_BITMAP_DECL_BINOP(and, 128, &)
_EVOASM_BITMAP_DECL_BINOP(or, 128, |)
_EVOASM_BITMAP_DECL_BINOP(andn, 128, &~)
_EVOASM_BITMAP_DECL_POPCOUNT(128)
_EVOASM_BITMAP_DECL_EQL(128)

_EVOASM_BITMAP_DECL_UNOP(not, 64, ~)
_EVOASM_BITMAP_DECL_BINOP(and, 64, &)
_EVOASM_BITMAP_DECL_BINOP(or, 64, |)
_EVOASM_BITMAP_DECL_POPCOUNT(64)
_EVOASM_BITMAP_DECL_EQL(64)


_EVOASM_BITMAP_DECL_EQL(1024)
