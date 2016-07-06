#pragma once

#include <stdint.h>
#include "evoasm-bitmap.h"
#include "evoasm-misc.h"

#define EVOASM_ARCH_PARAM_VAL_FORMAT PRId64
#define EVOASM_ARCH_PARAM_FORMAT PRIu32

#define _EVOASM_ARCH_PARAMS_HEADER \
  evoasm_arch_params_bitmap set;

typedef int64_t evoasm_arch_param_val;
typedef uint8_t evoasm_arch_param_id;
typedef evoasm_bitmap64 evoasm_arch_params_bitmap;

typedef struct {
  _EVOASM_ARCH_PARAMS_HEADER
  evoasm_arch_param_val vals[];
} evoasm_arch_params;

typedef struct {
  evoasm_arch_param_id id;
  evoasm_domain *domain;
} evoasm_arch_param;

static inline void
evoasm_arch_params_set(evoasm_arch_param_val *vals, evoasm_bitmap *set_params, evoasm_arch_param_id param, evoasm_arch_param_val val) {
  vals[param] = val;
  evoasm_bitmap_set(set_params, param);
}

static inline void
evoasm_arch_params_unset(evoasm_arch_param_val *vals, evoasm_bitmap *set_params, evoasm_arch_param_id param) {
  vals[param] = 0;
  evoasm_bitmap_unset(set_params, param);
}
