#pragma once

#include "awasm-util.h"

#include "awasm-edge-set.h"
#include "awasm-node-list.h"

typedef struct  {
  awasm_node_list nodes;
} awasm_graph;

typedef enum {
  AWASM_GRAPH_ERROR_CODE_OK,
  AWASM_GRAPH_ERROR_CODE_INVALID_ID,
  AWASM_GRAPH_ERROR_CODE_LINK_EXISTS,
  AWASM_GRAPH_ERROR_CODE_LINK_NOT_FOUND,
} awasm_graph_error_code;
