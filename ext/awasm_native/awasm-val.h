#pragma once

#include <stdint.h>
#include "awasm-sym.h"

typedef enum {
  AWASM_VAL_TYPE_U8,
  AWASM_VAL_TYPE_I64,
  AWASM_VAL_TYPE_U64,
  AWASM_VAL_TYPE_F64,
  AWASM_VAL_TYPE_F32,
  AWASM_VAL_TYPE_SYM
} awasm_val_type;

typedef struct {
  uint32_t idx;
} awasm_ref;

typedef struct {
  union {
    uint8_t  u8;
    int64_t  i64;
    uint64_t u64;
    double   f64;
    float    f32;
    awasm_sym sym;
    awasm_ref ref;
  };
  awasm_val_type type;

} awasm_val;
