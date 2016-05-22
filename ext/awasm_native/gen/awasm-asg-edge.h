#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "awasm-sym.h"


typedef struct {
  bool dir  : 1;
  bool free : 1;
  union {
    struct {
      uint16_t edge_idx;
      uint16_t node_idx;
      awasm_sym label;
    };
    uint16_t next_free;
  };
} awasm_asg_edge;

#define AWASM_ASG_EDGE_DIR_IN 0x0
#define AWASM_ASG_EDGE_DIR_OUT 0x1
