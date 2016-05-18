#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "awasm-edge-set.h"

typedef struct {
  uint32_t depth;
  uint32_t next_free;
  uint32_t idx;
  bool free : 1;
  awasm_edge_set edges;
} awasm_node;
