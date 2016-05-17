
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

uint32_t
awasm_graph_add(awasm_graph *graph, awasm_val val) {
  uint32_t node_index;
  awasm_node *node = awasm_node_list_push(&graph->nodes, &node_index);
  node->val = val;
  if(!awasm_edge_set_init(&node->edges, 0)) {
    if(!awasm_node_list_delete_at(&graph->nodes, node_index)) {
      /* must exist at this point, or something is wrong */
      awasm_assert_not_reached();
    }
  }
  return node_index;
}

#define SET_INVALID_NODE_ID_ERROR() \
  awasm_set_error(AWASM_ERROR_TYPE_GRAPH, AWASM_GRAPH_ERROR_CODE_INVALID_ID, NULL, \
     "one or both node ids %d, %d are invalid", from, to);

awasm_success
awasm_graph_link(awasm_graph *graph, uint32_t from, uint32_t to, awasm_val val) {

  awasm_node *node_from = awasm_node_list_get(&graph->nodes, from);
  awasm_node *node_to = awasm_node_list_get(&graph->nodes, to);

  if(node_from && node_to) {
    awasm_node *node1, *node2;
    awasm_edge *edge1, *edge2;
    uint32_t edge_index1, edge_index2;

    awasm_edge edge_out = {
        .dir = AWASM_EDGE_DIR_OUT,
        .val = val,
        .node_index = to
      };

    awasm_edge edge_in = {
        .dir = AWASM_EDGE_DIR_IN,
        .val = val,
        .node_index = from
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

    if(!awasm_edge_set_index(&node1->edges, edge1, &edge_index1)) {
      edge1 = awasm_edge_set_push(&node1->edges, &edge_index1);
      edge2 = awasm_edge_set_push(&node2->edges, &edge_index2);

      edge1->edge_index = edge_index2;
      edge2->edge_index = edge_index1;

      return true;
    } else {
      awasm_set_error(AWASM_ERROR_TYPE_GRAPH, AWASM_GRAPH_ERROR_CODE_LINK_EXISTS, NULL,
          "link between %d and %d already exists", from, to);
      return false;
    }
  } else {
    SET_INVALID_NODE_ID_ERROR();
    return false;
  }
}

awasm_success
awasm_graph_unlink(awasm_graph *graph, uint32_t from, uint32_t to, awasm_val val) {

  awasm_node *node_from = awasm_node_list_get(&graph->nodes, from);
  awasm_node *node_to = awasm_node_list_get(&graph->nodes, to);

  if(node_from && node_to) {
    uint32_t index;

    awasm_edge edge_out = {
      .dir = AWASM_EDGE_DIR_OUT,
      .val = val,
      .node_index = to
    };

    awasm_edge edge_in = {
      .dir = AWASM_EDGE_DIR_IN,
      .val = val,
      .node_index = from
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

    if(awasm_edge_set_index(&node1->edges, edge1, &index)) {
      edge1 = awasm_edge_set_delete_at(&node1->edges, index);
      assert(edge1);
      awasm_edge_set_delete_at(&node2->edges, edge1->edge_index);

      return true;
    } else {
      awasm_set_error(AWASM_ERROR_TYPE_GRAPH, AWASM_GRAPH_ERROR_CODE_LINK_NOT_FOUND, NULL,
          "link between %d and %d does not exist", from, to);
      return true;
    }
  } else {
    SET_INVALID_NODE_ID_ERROR();
    return false;
  }
}

uint32_t
awasm_graph_size(awasm_graph *graph) {
  return graph->nodes.len;
}

static awasm_success
awasm_graph_unlink_node(awasm_graph *graph, awasm_node *node, uint32_t node_id) {
  awasm_edge *edges = awasm_edge_set_data(&node->edges);
  uint32_t i;

  for(i = 0; i < node->edges.capa; i++) {
    awasm_edge *edge = &edges[i];
    if(!edge->free) {
      awasm_graph_error_code ret;
      if(edge->dir == AWASM_EDGE_DIR_IN) {
        ret = awasm_graph_unlink(graph, edge->node_index, node_id, edge->val);
      } else {
        ret = awasm_graph_unlink(graph, node_id, edge->node_index, edge->val);
      }

      if(!ret) return ret;
    }
  }
  return true;
}

bool
awasm_graph_delete(awasm_graph *graph, uint32_t node_id) {
  awasm_node *node;
  if((node = awasm_node_list_get(&graph->nodes, node_id))) {
    if(!awasm_graph_unlink_node(graph, node, node_id)) {
      return false;
    }

    awasm_edge_set_destroy(&node->edges);
    if(!awasm_node_list_delete_at(&graph->nodes, node_id)) {
      /* must exist at this point, or something is wrong */
      awasm_assert_not_reached();
    }

    return true;
  }
}
