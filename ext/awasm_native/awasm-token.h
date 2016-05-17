#pragma once

#include <stdint.h>

#include "awasm-val.h"

typedef struct {
  uint32_t begin;
  uint32_t end;
  uint32_t line;
  uint32_t col;
  uint32_t refc;
  awasm_val val;
} awasm_token;
