#include "awasm-src-graph.h"

void
awasm_src_graph_init(awasm_src_graph *src_graph, uint32_t graph_capa, uint32_t tokens_capa) {
  awasm_graph_init(&src_graph->graph, graph_capa);
  awasm_token_list_init(&src_graph->tokens, tokens_capa);
}

void
awasm_src_graph_destroy(awasm_src_graph *src_graph) {
  awasm_graph_destroy(&src_graph->graph);
  awasm_token_list_destroy(&src_graph->tokens);
}

awasm_success
awasm_src_graph_add(awasm_src_graph *src_graph, awasm_token **token, awasm_node **node) {
  AWASM_TRY(error, awasm_token_list_push, &src_graph->tokens, token);
  (*node)->idx = awasm_token_list_index(&src_graph->tokens, *token)
  AWASM_TRY(error, awasm_graph_add, &src_graph->graph, node);

  return true;

error:
  return false;
}
