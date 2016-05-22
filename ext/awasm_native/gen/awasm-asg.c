
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "awasm-asg.h"
#include "awasm-error.h"
#include "awasm-alloc.h"
#include "awasm-val.h"

#define AWASM_ASG_NULL_IDX (uint16_t) -1

void
awasm_asg_destroy(awasm_asg *graph) {
  awasm_asg_node_list_destroy(&graph->nodes);
  awasm_asg_edge_list_destroy(&graph->edges);
}

awasm_success
awasm_asg_init(awasm_asg *graph, uint16_t capa) {
  AWASM_TRY(nodes_error, awasm_asg_node_list_init, &graph->nodes, capa);
  AWASM_TRY(edges_error, awasm_asg_edge_list_init, &graph->edges, capa);

  return true;

nodes_error:
  return false;
edges_error:
  awasm_asg_node_list_destroy(&graph->nodes);
  return false;
}

awasm_success
awasm_asg_add(awasm_asg *graph, awasm_asg_node **node) {
  AWASM_TRY(error, awasm_asg_node_list_push, &graph->nodes, node, NULL);
  (*node)->edge_idx = AWASM_ASG_NULL_IDX;
  return true;

error:
  return false;
}

awasm_success
awasm_asg_link(awasm_asg *graph, awasm_asg_node *node_from, awasm_asg_node *node_to, awasm_asg_edge label) {

  uint16_t from = awasm_asg_node_index(graph, node_from);
  uint16_t to = awasm_asg_node_index(graph, node_to);

  awasm_asg_edge *edge_in, *edge_out;
  uint16_t edge_in_idx, edge_out_idx;

  AWASM_TRY(push1_error, awasm_asg_edge_list_push, &graph->edges, &edge_in, &edge_in_idx);
  AWASM_TRY(push2_error, awasm_asg_edge_list_push, &graph->edges, &edge_out, &edge_out_idx);

  *edge_out = {
      .dir = AWASM_ASG_EDGE_DIR_OUT,
      .label = label,
      .node_idx = from,
      .edge_idx = node_from->edge_idx,
  };

  *edge_in = {
      .dir = AWASM_ASG_EDGE_DIR_IN,
      .label = label,
      .node_idx = to,
      .edge_idx = node_to->edge_idx
  };

  node_from->edge_idx = edge_out_idx;
  node_to->edge_idx = edge_in_idx;

  return true;
}

static bool
awasm_asg_edge_eql(awasm_asg_edge *a, awasm_asg_edge b) {
  return a->dir == b->dir &&
       a->node_index == b->node_index &&
       a->index == b->index;

}

static awasm_asg_edge *
awasm_asg_delete_edge(awasm_asg *graph, awasm_asg_node *node, awasm_asg_edge *edge) {
  uint16_t i;

  for(i = node->edge_idx; i != AWASM_ASG_NULL_IDX;) {
    awasm_asg_edge *edge = awasm_asg_edge_list_get(&graph->edges, i);

    if(return a->dir == b->dir &&
       a->node_index == b->node_index &&
       a->index == b->index;
(edge, &edge_out)) {
      return awasm_asg_edge_list_delete(&graph->edges, edge)
    }
    i = edge->edge_idx;
  }

  return NULL;
}

awasm_success
awasm_asg_unlink(awasm_asg *graph, awasm_asg_node *node_from, awasm_asg_node *node_to, awasm_sym label) {

  uint16_t from = awasm_asg_node_index(graph, node_from);
  uint16_t to = awasm_asg_node_index(graph, node_to);

  awasm_asg_edge edge_out = {
    .dir = AWASM_ASG_EDGE_DIR_OUT,
    .label = label,
    .node_idx = to
  };

  awasm_asg_edge edge_in = {
    .dir = AWASM_ASG_EDGE_DIR_IN,
    .label = label,
    .node_idx = from
  };

  awasm_asg_delete_edge(graph, node_from, &edge_out);
  awasm_asg_delete_edge(graph, node_to, &edge_in);
  return true;
}

uint16_t
awasm_asg_size(awasm_asg *graph) {
  return graph->nodes.len;
}

static awasm_success
awasm_asg_unlink_node(awasm_asg *graph, awasm_asg_node *node) {
  awasm_asg_edge *edges = awasm_asg_edge_list_data(&node->edges);
  uint16_t i;

  for(i = node->edge_idx; i != AWASM_ASG_NULL_IDX;) {
    awasm_asg_edge *edge = awasm_asg_edge_list_get(&graph->edges, i);
    if(edge->dir == AWASM_ASG_EDGE_DIR_IN) {
      node1 = awasm_asg_node_list_get(&graph->nodes, edge->node_idx);
      node2 = node;
    } else {
      node1 = node;
      node2 = awasm_asg_node_list_get(&graph->nodes, edge->node_idx);
    }
    if(!awasm_asg_unlink(graph, node1, node2, edge->idx)) return false;
  }
  return true;
}

bool
awasm_asg_delete(awasm_asg *graph, awasm_asg_node *node) {
  if(!awasm_asg_unlink_node(graph, node)) {
    return false;
  }
  if(!awasm_asg_node_list_delete(&graph->nodes, node)) {
    /* must exist at this point, or something is wrong */
    awasm_assert_not_reached();
  }
  return true;
}
