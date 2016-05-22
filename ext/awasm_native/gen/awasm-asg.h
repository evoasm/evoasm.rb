#pragma once

#include "awasm-util.h"

#include "awasm-asg-edge-list.h"
#include "awasm-asg-node-list.h"
#include "awasm-sym.h"


typedef struct  {
  awasm_asg_node_list nodes;
  awasm_asg_edge_list edges;
} awasm_asg;

static inline uint16_t
awasm_asg_node_index(awasm_asg *graph, awasm_asg_node *node) {
  return (uint16_t)(node - graph->nodes.data);
}

void awasm_asg_destroy(awasm_asg *graph);
awasm_success awasm_asg_init(awasm_asg *graph, uint16_t capa);
awasm_success awasm_asg_add(awasm_asg *graph, awasm_asg_node **node);
awasm_success awasm_asg_link(awasm_asg *graph, awasm_asg_node *from, awasm_asg_node *to, awasm_sym label);

