#pragma once

#include "evoasm-util.h"

#include "evoasm-asg-edge-list.h"
#include "evoasm-asg-node-list.h"
#include "evoasm-sym.h"


typedef struct  {
  evoasm_asg_node_list nodes;
  evoasm_asg_edge_list edges;
} evoasm_asg;

static inline uint32_t
evoasm_asg_node_index(evoasm_asg *graph, evoasm_asg_node *node) {
  return (uint32_t)(node - graph->nodes.data);
}

void evoasm_asg_destroy(evoasm_asg *graph);
evoasm_success evoasm_asg_init(evoasm_asg *graph, uint32_t capa);
evoasm_success evoasm_asg_add(evoasm_asg *graph, evoasm_asg_node **node);
evoasm_success evoasm_asg_link(evoasm_asg *graph, evoasm_asg_node *from, evoasm_asg_node *to, evoasm_sym label);

