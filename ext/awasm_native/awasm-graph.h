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

static inline uint32_t
awasm_graph_node_index(awasm_graph *graph, awasm_node *node) {
  return (uint32_t)(node - graph->nodes.data);
}

void awasm_graph_destroy(awasm_graph *graph);
awasm_success awasm_graph_init(awasm_graph *graph, uint32_t capa);
uint32_t awasm_graph_add(awasm_graph *graph, awasm_node **node);
awasm_success
awasm_graph_link(awasm_graph *graph, awasm_node *from, awasm_node *to, uint32_t idx);

