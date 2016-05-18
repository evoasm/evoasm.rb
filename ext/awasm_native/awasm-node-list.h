#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "awasm-node.h"


#if 0 > 0
#  define AWASM_SEQ_DATA(seq) (seq->data != NULL ? seq->data : seq->_data)
#else
#  define AWASM_SEQ_DATA(seq) (seq->data)
#endif

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

static inline uint32_t
awasm_node_list_index(awasm_node_list *seq, awasm_node *e) {
  return (uint32_t)(e - AWASM_SEQ_DATA(seq));
}

void awasm_node_list_clear(awasm_node_list *seq, uint32_t start, uint32_t end);
awasm_success awasm_node_list_init(awasm_node_list *seq, uint32_t capa);
awasm_node *awasm_node_list_push(awasm_node_list *seq, awasm_node **e);
awasm_node *awasm_node_list_get(awasm_node_list *seq, uint32_t index);
awasm_node *awasm_node_list_delete(awasm_node_list *seq, awasm_node *e);
void awasm_node_list_destroy(awasm_node_list *seq);
awasm_node * awasm_node_list_data(awasm_node_list *seq);
bool awasm_node_list_find(awasm_node_list *seq, awasm_node *value, uint32_t *index);
