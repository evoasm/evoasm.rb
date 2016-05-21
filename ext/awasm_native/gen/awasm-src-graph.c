
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "awasm-src-graph.h"
#include "awasm-error.h"
#include "awasm-alloc.h"
#include "awasm-val.h"

#define AWASM_SRC_GRAPH_NULL_IDX (uint16_t) -1

void
awasm_src_graph_destroy(awasm_src_graph *graph) {
  awasm_src_node_list_destroy(&graph->nodes);
  awasm_src_edge_list_destroy(&graph->edges);
}

awasm_success
awasm_src_graph_init(awasm_src_graph *graph, uint16_t capa) {
  AWASM_TRY(nodes_error, awasm_src_node_list_init, &graph->nodes, capa);
  AWASM_TRY(edges_error, awasm_src_edge_list_init, &graph->edges, capa);

  return true;

nodes_error:
  return false;
edges_error:
  awasm_src_node_list_destroy(&graph->nodes);
  return false;
}

awasm_success
awasm_src_graph_add(awasm_src_graph *graph, awasm_src_node **node) {
  AWASM_TRY(error, awasm_src_node_list_push, &graph->nodes, node, NULL);
  (*node)->edge_idx = AWASM_SRC_GRAPH_NULL_IDX;
  return true;

error:
  return false;
}

awasm_success
awasm_src_graph_link(awasm_src_graph *graph, awasm_src_node *node_from, awasm_src_node *node_to, awasm_src_edge label) {

  uint16_t from = awasm_src_graph_node_index(graph, node_from);
  uint16_t to = awasm_src_graph_node_index(graph, node_to);

  awasm_src_edge *edge_in, *edge_out;
  uint16_t edge_in_idx, edge_out_idx;

  AWASM_TRY(push1_error, awasm_src_edge_list_push, &graph->edges, &edge_in, &edge_in_idx);
  AWASM_TRY(push2_error, awasm_src_edge_list_push, &graph->edges, &edge_out, &edge_out_idx);

  *edge_out = {
      .dir = AWASM_SRC_EDGE_DIR_OUT,
      .label = label,
      .node_idx = from,
      .edge_idx = node_from->edge_idx,
  };

  *edge_in = {
      .dir = AWASM_SRC_EDGE_DIR_IN,
      .label = label,
      .node_idx = to,
      .edge_idx = node_to->edge_idx
  };

  node_from->edge_idx = edge_out_idx;
  node_to->edge_idx = edge_in_idx;

  return true;
}

static bool
awasm_src_graph_edge_eql(awasm_src_edge *a, awasm_src_edge b) {
  return a->dir == b->dir &&
       a->node_index == b->node_index &&
       a->index == b->index;

}

static awasm_src_edge *
awasm_src_graph_delete_edge(awasm_src_graph *graph, awasm_src_node *node, awasm_src_edge *edge) {
  uint16_t i;

  for(i = node->edge_idx; i != AWASM_SRC_GRAPH_NULL_IDX;) {
    awasm_src_edge *edge = awasm_src_edge_list_get(&graph->edges, i);

    if(return a->dir == b->dir &&
       a->node_index == b->node_index &&
       a->index == b->index;
(edge, &edge_out)) {
      return awasm_src_edge_list_delete(&graph->edges, edge)
    }
    i = edge->edge_idx;
  }

  return NULL;
}

awasm_success
awasm_src_graph_unlink(awasm_src_graph *graph, awasm_src_node *node_from, awasm_src_node *node_to, awasm_sym label) {

  uint16_t from = awasm_src_graph_node_index(graph, node_from);
  uint16_t to = awasm_src_graph_node_index(graph, node_to);

  awasm_src_edge edge_out = {
    .dir = AWASM_SRC_EDGE_DIR_OUT,
    .label = label,
    .node_idx = to
  };

  awasm_src_edge edge_in = {
    .dir = AWASM_SRC_EDGE_DIR_IN,
    .label = label,
    .node_idx = from
  };

  awasm_src_graph_delete_edge(graph, node_from, &edge_out);
  awasm_src_graph_delete_edge(graph, node_to, &edge_in);
  return true;
}

uint16_t
awasm_src_graph_size(awasm_src_graph *graph) {
  return graph->nodes.len;
}

static awasm_success
awasm_src_graph_unlink_node(awasm_src_graph *graph, awasm_src_node *node) {
  awasm_src_edge *edges = awasm_src_edge_list_data(&node->edges);
  uint16_t i;

  for(i = node->edge_idx; i != AWASM_SRC_GRAPH_NULL_IDX;) {
    awasm_src_edge *edge = awasm_src_edge_list_get(&graph->edges, i);
    if(edge->dir == AWASM_SRC_EDGE_DIR_IN) {
      node1 = awasm_src_node_list_get(&graph->nodes, edge->node_idx);
      node2 = node;
    } else {
      node1 = node;
      node2 = awasm_src_node_list_get(&graph->nodes, edge->node_idx);
    }
    if(!awasm_src_graph_unlink(graph, node1, node2, edge->idx)) return false;
  }
  return true;
}

bool
awasm_src_graph_delete(awasm_src_graph *graph, awasm_src_node *node) {
  if(!awasm_src_graph_unlink_node(graph, node)) {
    return false;
  }
  if(!awasm_src_node_list_delete(&graph->nodes, node)) {
    /* must exist at this point, or something is wrong */
    awasm_assert_not_reached();
  }
  return true;
}
