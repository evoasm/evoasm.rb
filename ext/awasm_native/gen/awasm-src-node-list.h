#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "awasm-src-node.h"

#if 0 > 0
#  define AWASM_SRC_NODE_LIST_DATA(seq) (seq->data != NULL ? seq->data : seq->_data)
#else
#  define AWASM_SRC_NODE_LIST_DATA(seq) (seq->data)
#endif

#define AWASM_SRC_NODE_LIST_NULL_IDX ((uint16_t)-1)

typedef struct awasm_src_node_list {
  uint16_t capa;
  uint16_t len;
  uint16_t first_free;
  uint16_t last_free;
  awasm_src_node *data;

#if 0 > 0
  awasm_src_node _data[0];
#endif
} awasm_src_node_list;

static inline uint32_t
awasm_src_node_list_index(awasm_src_node_list *seq, awasm_src_node *e) {
  return (uint32_t)(e - AWASM_SRC_NODE_LIST_DATA(seq));
}

static inline awasm_src_node *
awasm_src_node_list_get(awasm_src_node_list *seq, uint16_t index) {
#if 0
  if(index >= seq->capa) {
    return NULL;
  }
  return AWASM_SRC_NODE_LIST_DATA(seq)[index].free ? NULL : &AWASM_SRC_NODE_LIST_DATA(seq)[index];
#endif
  return &AWASM_SRC_NODE_LIST_DATA(seq)[index];
}

awasm_success _awasm_src_node_list_grow(awasm_src_node_list *seq);

static inline awasm_success
awasm_src_node_list_push(awasm_src_node_list *seq, awasm_src_node **ee, uint16_t *ridx) {
  if(seq->first_free == AWASM_SRC_NODE_LIST_NULL_IDX) {
    if(!_awasm_src_node_list_grow(seq)) {
      return false;
    }
  }

  {
    awasm_src_node *entry = &AWASM_SRC_NODE_LIST_DATA(seq)[seq->first_free];

    uint16_t idx = seq->first_free;

    // used up last free slot
    if(entry->next_free == AWASM_SRC_NODE_LIST_NULL_IDX){
      assert(idx == seq->last_free);
      seq->last_free = AWASM_SRC_NODE_LIST_NULL_IDX;
    }

    seq->first_free = entry->next_free;

    entry->free = false;
    entry->next_free = AWASM_SRC_NODE_LIST_NULL_IDX;

    seq->len++;

    *ee = entry;
    if(ridx) {
      *ridx = idx;
    }
    return true;
  }
}

void awasm_src_node_list_clear(awasm_src_node_list *seq, uint32_t start, uint32_t end);
awasm_success awasm_src_node_list_init(awasm_src_node_list *seq, uint16_t capa);
awasm_src_node *awasm_src_node_list_delete(awasm_src_node_list *seq, awasm_src_node *e);
void awasm_src_node_list_destroy(awasm_src_node_list *seq);
awasm_src_node * awasm_src_node_list_data(awasm_src_node_list *seq);
