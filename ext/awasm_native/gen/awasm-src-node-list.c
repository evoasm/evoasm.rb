#include <assert.h>
#include <errno.h>

#include "awasm-src-node-list.h"
#include "awasm-alloc.h"

#include "awasm-src-node.h"

void
awasm_src_node_list_clear(awasm_src_node_list *seq, uint16_t start, uint16_t end) {
  for(uint16_t i = start; i < end - 1; i++) {
    AWASM_SRC_NODE_LIST_DATA(seq)[i].free = true;
    AWASM_SRC_NODE_LIST_DATA(seq)[i].next_free = i + 1;
  }
  AWASM_SRC_NODE_LIST_DATA(seq)[end - 1].next_free = AWASM_SRC_NODE_LIST_NULL_IDX;
  AWASM_SRC_NODE_LIST_DATA(seq)[end - 1].free = true;

  seq->last_free = end - 1;
}


awasm_src_node *
awasm_src_node_list_data(awasm_src_node_list *seq) {
 return AWASM_SRC_NODE_LIST_DATA(seq);
}

awasm_success
awasm_src_node_list_init(awasm_src_node_list *seq, uint16_t capa) {

#if 0 > 0
  seq->data = NULL;
  seq->capa = AWASM_SEQ_EMBED_N;
#else
  size_t size = sizeof(awasm_src_node) * capa;
  seq->data = awasm_malloc(size);
  if(seq->data == NULL) {
    awasm_set_error(AWASM_ERROR_TYPE_MEMORY, AWASM_ERROR_CODE_NONE,
        NULL, "Allocationg buffer of size %zu failed: %s", size, strerror(errno));
    return false;
  }
  seq->capa = capa;
#endif

  seq->first_free = 0;
  seq->len = 0;

  awasm_src_node_list_clear(seq, 0, seq->capa);
  return true;
}

awasm_success
_awasm_src_node_list_grow(awasm_src_node_list *seq) {
  uint16_t new_capa = seq->capa + seq->capa / 2;

#if 0 > 0
  if(seq->data == NULL) {
    seq->data = malloc(sizeof(awasm_src_node) * new_capa);
    memcpy(seq->data, seq->_data, sizeof(awasm_src_node) * seq->capa);
    goto update;
  }
#endif

  {
    size_t size = sizeof(awasm_src_node) * new_capa;
    awasm_src_node *new_data = awasm_realloc(seq->data, size);

    if(AWASM_UNLIKELY(new_data == NULL)) {
      awasm_set_error(AWASM_ERROR_TYPE_MEMORY, AWASM_ERROR_CODE_NONE,
          NULL, "Reallocationg buffer of size %zu failed: %s", size, strerror(errno));
      return false;
    }
  }
update:
  seq->first_free = seq->capa;
  awasm_src_node_list_clear(seq, seq->capa, new_capa);
  seq->capa = new_capa;
  return true;
}

awasm_src_node *
awasm_src_node_list_delete(awasm_src_node_list *seq, awasm_src_node *e) {
  uint16_t idx = awasm_src_node_list_index(seq, e);

  e->next_free = seq->first_free;
  e->free = true;

  // only free slot
  if(seq->last_free == AWASM_SRC_NODE_LIST_NULL_IDX) {
    seq->last_free = idx;
  }

  seq->first_free = idx;
  seq->len--;
  return e;
}

bool
awasm_src_node_list_eql(awasm_src_node_list *a, awasm_src_node_list *b) {
  awasm_src_nodeql
}

bool
awasm_src_node_list_find(awasm_src_node_list *seq, awasm_src_node *value, uint16_t *index) {

  if(seq->len == 0) return false;

  for(uint16_t i = 0; i < seq->capa; i++) {
    if(!AWASM_SRC_NODE_LIST_DATA(seq)[i].free) {
      if(awasm_src_node_list_cmp(value, &AWASM_SRC_NODE_LIST_DATA(seq)[i])) {
        if(index != NULL) *index = i;
        return true;
      }
    }
  }
  return false;
}

void
awasm_src_node_list_destroy(awasm_src_node_list *seq) {
  awasm_free(seq->data);
}
