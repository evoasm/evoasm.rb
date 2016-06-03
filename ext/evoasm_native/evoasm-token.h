#pragma once

#include <stdint.h>

#include "evoasm-val.h"

typedef struct {
  uint32_t begin;
  uint32_t end;
  uint32_t line;
  uint32_t col;
  uint16_t refc;
  uint16_t id;
  evoasm_val val;
} evoasm_token;
