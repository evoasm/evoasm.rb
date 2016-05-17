#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "awasm-node.h"


typedef struct awasm_node_list {
  uint32_t capa;
  uint32_t len;
  uint32_t first_free;
  uint32_t last_free;
  awasm_node *data;

#if 0 > 0
  awasm_node _data[0];
#endif
} awasm_node_list;

void awasm_node_list_clear(awasm_node_list *seq, uint32_t start, uint32_t end);
awasm_success awasm_node_list_init(awasm_node_list *seq, uint32_t capa);
awasm_node *awasm_node_list_push(awasm_node_list *seq, uint32_t *index_);
awasm_node *awasm_node_list_get(awasm_node_list *seq, uint32_t index);
awasm_node *awasm_node_list_delete_at(awasm_node_list *seq, uint32_t index);
