#pragma once

#include "awasm-util.h"

#include "awasm-src-edge-list.h"
#include "awasm-src-node-list.h"
#include "awasm-sym.h"


typedef struct  {
  awasm_src_node_list nodes;
  awasm_src_edge_list edges;
} awasm_src_graph;

static inline uint16_t
awasm_src_graph_node_index(awasm_src_graph *graph, awasm_src_node *node) {
  return (uint16_t)(node - graph->nodes.data);
}

void awasm_src_graph_destroy(awasm_src_graph *graph);
awasm_success awasm_src_graph_init(awasm_src_graph *graph, uint16_t capa);
awasm_success awasm_src_graph_add(awasm_src_graph *graph, awasm_src_node **node);
awasm_success awasm_src_graph_link(awasm_src_graph *graph, awasm_src_node *from, awasm_src_node *to, awasm_sym label);

