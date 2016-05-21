#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "awasm-token.h"


typedef struct {
  bool free : 1;
  union {
    struct {
      awasm_token token;
      uint16_t edge_idx;
    };
    uint16_t next_free;
  };
} awasm_src_node;
