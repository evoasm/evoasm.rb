#pragma once

#include "awasm-token-list.h"
#include "awasm-graph.h"

typedef struct {
  awasm_graph graph;
  awasm_token_list tokens;
} awasm_src_graph;
