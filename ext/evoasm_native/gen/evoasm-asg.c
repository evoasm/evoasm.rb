
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "evoasm-asg.h"
#include "evoasm-error.h"
#include "evoasm-alloc.h"
#include "evoasm-val.h"

#define EVOASM_ASG_NULL_IDX (uint32_t) -1

void
evoasm_asg_destroy(evoasm_asg *graph) {
  evoasm_asg_node_list_destroy(&graph->nodes);
  evoasm_asg_edge_list_destroy(&graph->edges);
}

evoasm_success
evoasm_asg_init(evoasm_asg *graph, uint32_t capa) {
  EVOASM_TRY(nodes_error, evoasm_asg_node_list_init, &graph->nodes, capa);
  EVOASM_TRY(edges_error, evoasm_asg_edge_list_init, &graph->edges, capa);

  return true;

nodes_error:
  return false;
edges_error:
  evoasm_asg_node_list_destroy(&graph->nodes);
  return false;
}

evoasm_success
evoasm_asg_add(evoasm_asg *graph, evoasm_asg_node **node) {
  EVOASM_TRY(error, evoasm_asg_node_list_push, &graph->nodes, node, NULL);
  (*node)->edge_idx = EVOASM_ASG_NULL_IDX;
  return true;

error:
  return false;
}

evoasm_success
evoasm_asg_link(evoasm_asg *graph, evoasm_asg_node *node_from, evoasm_asg_node *node_to, evoasm_asg_edge label) {

  uint32_t from = evoasm_asg_node_index(graph, node_from);
  uint32_t to = evoasm_asg_node_index(graph, node_to);

  evoasm_asg_edge *edge_in, *edge_out;
  uint32_t edge_in_idx, edge_out_idx;

  EVOASM_TRY(push1_error, evoasm_asg_edge_list_push, &graph->edges, &edge_in, &edge_in_idx);
  EVOASM_TRY(push2_error, evoasm_asg_edge_list_push, &graph->edges, &edge_out, &edge_out_idx);

  *edge_out = {
      .dir = EVOASM_ASG_EDGE_DIR_OUT,
      .label = label,
      .node_idx = from,
      .edge_idx = node_from->edge_idx,
  };

  *edge_in = {
      .dir = EVOASM_ASG_EDGE_DIR_IN,
      .label = label,
      .node_idx = to,
      .edge_idx = node_to->edge_idx
  };

  node_from->edge_idx = edge_out_idx;
  node_to->edge_idx = edge_in_idx;

  return true;
}

static bool
evoasm_asg_edge_eql(evoasm_asg_edge *a, evoasm_asg_edge b) {
  return a->dir == b->dir &&
       a->node_index == b->node_index &&
       a->index == b->index;

}

static evoasm_asg_edge *
evoasm_asg_delete_edge(evoasm_asg *graph, evoasm_asg_node *node, evoasm_asg_edge *edge) {
  uint32_t i;

  for(i = node->edge_idx; i != EVOASM_ASG_NULL_IDX;) {
    evoasm_asg_edge *edge = evoasm_asg_edge_list_get(&graph->edges, i);

    if(return a->dir == b->dir &&
       a->node_index == b->node_index &&
       a->index == b->index;
(edge, &edge_out)) {
      return evoasm_asg_edge_list_delete(&graph->edges, edge)
    }
    i = edge->edge_idx;
  }

  return NULL;
}

evoasm_success
evoasm_asg_unlink(evoasm_asg *graph, evoasm_asg_node *node_from, evoasm_asg_node *node_to, evoasm_sym label) {

  uint32_t from = evoasm_asg_node_index(graph, node_from);
  uint32_t to = evoasm_asg_node_index(graph, node_to);

  evoasm_asg_edge edge_out = {
    .dir = EVOASM_ASG_EDGE_DIR_OUT,
    .label = label,
    .node_idx = to
  };

  evoasm_asg_edge edge_in = {
    .dir = EVOASM_ASG_EDGE_DIR_IN,
    .label = label,
    .node_idx = from
  };

  evoasm_asg_delete_edge(graph, node_from, &edge_out);
  evoasm_asg_delete_edge(graph, node_to, &edge_in);
  return true;
}

uint32_t
evoasm_asg_size(evoasm_asg *graph) {
  return graph->nodes.len;
}

static evoasm_success
evoasm_asg_unlink_node(evoasm_asg *graph, evoasm_asg_node *node) {
  evoasm_asg_edge *edges = evoasm_asg_edge_list_data(&node->edges);
  uint32_t i;

  for(i = node->edge_idx; i != EVOASM_ASG_NULL_IDX;) {
    evoasm_asg_edge *edge = evoasm_asg_edge_list_get(&graph->edges, i);
    if(edge->dir == EVOASM_ASG_EDGE_DIR_IN) {
      node1 = evoasm_asg_node_list_get(&graph->nodes, edge->node_idx);
      node2 = node;
    } else {
      node1 = node;
      node2 = evoasm_asg_node_list_get(&graph->nodes, edge->node_idx);
    }
    if(!evoasm_asg_unlink(graph, node1, node2, edge->idx)) return false;
  }
  return true;
}

bool
evoasm_asg_delete(evoasm_asg *graph, evoasm_asg_node *node) {
  if(!evoasm_asg_unlink_node(graph, node)) {
    return false;
  }
  if(!evoasm_asg_node_list_delete(&graph->nodes, node)) {
    /* must exist at this point, or something is wrong */
    evoasm_assert_not_reached();
  }
  return true;
}
