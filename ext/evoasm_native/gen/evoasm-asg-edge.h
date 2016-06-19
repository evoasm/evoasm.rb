#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "evoasm-sym.h"


typedef struct {
  bool dir  : 1;
  bool free : 1;
  union {
    struct {
      uint16_t edge_idx;
      uint16_t node_idx;
      evoasm_sym label;
    };
    uint16_t next_free;
  };
} evoasm_asg_edge;

#define EVOASM_ASG_EDGE_DIR_IN 0x0
#define EVOASM_ASG_EDGE_DIR_OUT 0x1
