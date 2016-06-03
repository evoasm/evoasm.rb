#pragma once

#include <stdint.h>
#include "evoasm-sym.h"

typedef enum {
  EVOASM_VAL_TYPE_U8,
  EVOASM_VAL_TYPE_I64,
  EVOASM_VAL_TYPE_U64,
  EVOASM_VAL_TYPE_F64,
  EVOASM_VAL_TYPE_F32,
  EVOASM_VAL_TYPE_SYM
} evoasm_val_type;

typedef struct {
  uint32_t idx;
} evoasm_ref;

typedef struct {
  union {
    uint8_t  u8;
    int64_t  i64;
    uint64_t u64;
    double   f64;
    float    f32;
    evoasm_sym sym;
    evoasm_ref ref;
  };
  evoasm_val_type type;

} evoasm_val;
