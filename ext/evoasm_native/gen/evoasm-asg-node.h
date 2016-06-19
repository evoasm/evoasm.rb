#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "evoasm-token.h"


typedef struct {
  bool free : 1;
  union {
    struct {
      evoasm_token token;
      uint16_t edge_idx;
    };
    uint16_t next_free;
  };
} evoasm_asg_node;
