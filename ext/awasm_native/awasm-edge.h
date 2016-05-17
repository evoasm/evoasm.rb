#pragma once

#include <stdint.h>
#include <stdbool.h>

typedef struct {
  bool dir  : 1;
  bool free : 1;
  uint32_t edge_index;
  uint32_t node_index;
  uint32_t next_free;
  uint32_t index;
} awasm_edge;

#define AWASM_EDGE_DIR_IN 0x0
#define AWASM_EDGE_DIR_OUT 0x1
