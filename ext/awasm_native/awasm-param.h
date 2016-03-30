#pragma once

#include <stdint.h>
#include "awasm-bitmap.h"
#include "awasm-misc.h"

#define AWASM_ARCH_PARAM_VAL_FORMAT PRId64
#define AWASM_ARCH_PARAM_FORMAT PRIu32

#define _AWASM_ARCH_PARAMS_HEADER \
  awasm_arch_params_bitmap set;

typedef int64_t awasm_arch_param_val;
typedef uint8_t awasm_arch_param_id;
typedef awasm_bitmap64 awasm_arch_params_bitmap;

typedef struct {
  _AWASM_ARCH_PARAMS_HEADER
  awasm_arch_param_val vals[];
} awasm_arch_params;

typedef struct {
  awasm_arch_param_id id;
  awasm_domain *domain;
} awasm_arch_param;

static inline void
awasm_arch_params_set(awasm_arch_param_val *vals, awasm_bitmap *set_params, awasm_arch_param_id param, awasm_arch_param_val val) {
  vals[param] = val;
  awasm_bitmap_set(set_params, param);
}

static inline void
awasm_arch_params_unset(awasm_arch_param_val *vals, awasm_bitmap *set_params, awasm_arch_param_id param) {
  vals[param] = 0;
  awasm_bitmap_unset(set_params, param);
}
