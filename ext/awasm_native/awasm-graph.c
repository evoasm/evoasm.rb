
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "awasm-graph.h"
#include "awasm-error.h"
#include "awasm-alloc.h"
#include "awasm-val.h"

void
awasm_graph_destroy(awasm_graph *graph) {
  uint32_t i;
  awasm_node *nodes = awasm_node_list_data(&graph->nodes);

  for(i = 0; i < graph->nodes.capa; i++) {
    if(!nodes[i].free) {
      awasm_edge_set_destroy(&nodes[i].edges);
    }
  }
  awasm_node_list_destroy(&graph->nodes);
}

awasm_success
awasm_graph_init(awasm_graph *graph, uint32_t capa) {
  return awasm_node_list_init(&graph->nodes, capa);
}

awasm_success
awasm_graph_add(awasm_graph *graph, awasm_node **node) {
  AWASM_TRY(error, awasm_node_list_push, &graph->nodes, node);

  if(!awasm_edge_set_init(&(*node)->edges, 0)) {
    if(!awasm_node_list_delete(&graph->nodes, *node)) {
      /* must exist at this point, or something is wrong */
      awasm_assert_not_reached();
    }
  }
  return true;

error:
  return false;
}

#define SET_INVALID_NODE_ID_ERROR() \
  awasm_set_error(AWASM_ERROR_TYPE_GRAPH, AWASM_GRAPH_ERROR_CODE_INVALID_ID, NULL, \
     "one or both node ids %d, %d are invalid", from, to);


awasm_success
awasm_graph_link(awasm_graph *graph, awasm_node *node_from, awasm_node *node_to, uint32_t idx) {

  uint32_t from = awasm_graph_node_index(graph, node_from);
  uint32_t to = awasm_graph_node_index(graph, node_to);

  awasm_node *node1, *node2;
  awasm_edge *edge1, *edge2;
  uint32_t edge_index1, edge_index2;

  awasm_edge edge_out = {
      .dir = AWASM_EDGE_DIR_OUT,
      .idx = idx,
      .node_idx = from
  };

  awasm_edge edge_in = {
      .dir = AWASM_EDGE_DIR_IN,
      .idx = idx,
      .node_idx = to
  };

  if(node_from->edges.len <= node_to->edges.len) {
    node1 = node_from;
    node2 = node_to;
    edge1 = &edge_out;
    edge2 = &edge_in;
  } else {
    node1 = node_to;
    node2 = node_from;
    edge1 = &edge_in;
    edge2 = &edge_out;
  }

  if(!awasm_edge_set_find(&node1->edges, edge1, &edge_index1)) {
    edge1 = awasm_edge_set_push(&node1->edges, &edge1);
    edge2 = awasm_edge_set_push(&node2->edges, &edge2);

    edge1->edge_idx = edge_index2;
    edge2->edge_idx = edge_index1;

    return true;
  } else {
    awasm_set_error(AWASM_ERROR_TYPE_GRAPH, AWASM_GRAPH_ERROR_CODE_LINK_EXISTS, NULL,
        "link between %d and %d already exists", from, to);
    return false;
  }
}

awasm_success
awasm_graph_unlink(awasm_graph *graph, awasm_node *node_from, awasm_node *node_to, uint32_t idx) {

  uint32_t from = awasm_graph_node_index(graph, node_from);
  uint32_t to = awasm_graph_node_index(graph, node_to);
  uint32_t index;

  awasm_edge edge_out = {
    .dir = AWASM_EDGE_DIR_OUT,
    .idx = idx,
    .node_idx = to
  };

  awasm_edge edge_in = {
    .dir = AWASM_EDGE_DIR_IN,
    .idx = idx,
    .node_idx = from
  };

  awasm_node *node1, *node2;
  awasm_edge *edge1, *edge2;

  if(node_from->edges.len <= node_to->edges.len) {
    node1 = node_from;
    node2 = node_to;
    edge1 = &edge_out;
    edge2 = &edge_in;
  } else {
    node1 = node_to;
    node2 = node_from;
    edge1 = &edge_in;
    edge2 = &edge_out;
  }

  (void) edge2;

  if(awasm_edge_set_find(&node1->edges, edge1, &index)) {
    edge1 = awasm_edge_set_delete(&node1->edges, edge1);
    assert(edge1);
    awasm_edge_set_delete(&node2->edges, edge1);
    return true;
  } else {
    awasm_set_error(AWASM_ERROR_TYPE_GRAPH, AWASM_GRAPH_ERROR_CODE_LINK_NOT_FOUND, NULL,
        "link between %d and %d does not exist", from, to);
    return true;
  }
}

uint32_t
awasm_graph_size(awasm_graph *graph) {
  return graph->nodes.len;
}

static awasm_success
awasm_graph_unlink_node(awasm_graph *graph, awasm_node *node) {
  awasm_edge *edges = awasm_edge_set_data(&node->edges);
  uint32_t i;

  for(i = 0; i < node->edges.capa; i++) {
    awasm_edge *edge = &edges[i];
    if(!edge->free) {
      awasm_node *node1, *node2;

      if(edge->dir == AWASM_EDGE_DIR_IN) {
        node1 = awasm_node_list_get(&graph->nodes, edge->node_idx);
        node2 = node;
      } else {
        node1 = node;
        node2 = awasm_node_list_get(&graph->nodes, edge->node_idx);
      }
      if(!awasm_graph_unlink(graph, node1, node2, edge->idx)) return false;
    }
  }
  return true;
}

bool
awasm_graph_delete(awasm_graph *graph, awasm_node *node) {
  if(!awasm_graph_unlink_node(graph, node)) {
    return false;
  }
  awasm_edge_set_destroy(&node->edges);
  if(!awasm_node_list_delete(&graph->nodes, node)) {
    /* must exist at this point, or something is wrong */
    awasm_assert_not_reached();
  }
  return true;
}
