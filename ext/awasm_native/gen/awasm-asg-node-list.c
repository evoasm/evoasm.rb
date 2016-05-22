#include <assert.h>
#include <errno.h>

#include "awasm-asg-node-list.h"
#include "awasm-alloc.h"

#include "awasm-asg-node.h"

void
awasm_asg_node_list_clear(awasm_asg_node_list *seq, uint16_t start, uint16_t end) {
  for(uint16_t i = start; i < end - 1; i++) {
    AWASM_ASG_NODE_LIST_DATA(seq)[i].free = true;
    AWASM_ASG_NODE_LIST_DATA(seq)[i].next_free = i + 1;
  }
  AWASM_ASG_NODE_LIST_DATA(seq)[end - 1].next_free = AWASM_ASG_NODE_LIST_NULL_IDX;
  AWASM_ASG_NODE_LIST_DATA(seq)[end - 1].free = true;

  seq->last_free = end - 1;
}


awasm_asg_node *
awasm_asg_node_list_data(awasm_asg_node_list *seq) {
 return AWASM_ASG_NODE_LIST_DATA(seq);
}

awasm_success
awasm_asg_node_list_init(awasm_asg_node_list *seq, uint16_t capa) {

#if 0 > 0
  seq->data = NULL;
  seq->capa = AWASM_SEQ_EMBED_N;
#else
  size_t size = sizeof(awasm_asg_node) * capa;
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

  awasm_asg_node_list_clear(seq, 0, seq->capa);
  return true;
}

awasm_success
_awasm_asg_node_list_grow(awasm_asg_node_list *seq) {
  uint16_t new_capa = seq->capa + seq->capa / 2;

#if 0 > 0
  if(seq->data == NULL) {
    seq->data = malloc(sizeof(awasm_asg_node) * new_capa);
    memcpy(seq->data, seq->_data, sizeof(awasm_asg_node) * seq->capa);
    goto update;
  }
#endif

  {
    size_t size = sizeof(awasm_asg_node) * new_capa;
    awasm_asg_node *new_data = awasm_realloc(seq->data, size);

    if(AWASM_UNLIKELY(new_data == NULL)) {
      awasm_set_error(AWASM_ERROR_TYPE_MEMORY, AWASM_ERROR_CODE_NONE,
          NULL, "Reallocationg buffer of size %zu failed: %s", size, strerror(errno));
      return false;
    }
  }
update:
  seq->first_free = seq->capa;
  awasm_asg_node_list_clear(seq, seq->capa, new_capa);
  seq->capa = new_capa;
  return true;
}

awasm_asg_node *
awasm_asg_node_list_delete(awasm_asg_node_list *seq, awasm_asg_node *e) {
  uint16_t idx = awasm_asg_node_list_index(seq, e);

  e->next_free = seq->first_free;
  e->free = true;

  // only free slot
  if(seq->last_free == AWASM_ASG_NODE_LIST_NULL_IDX) {
    seq->last_free = idx;
  }

  seq->first_free = idx;
  seq->len--;
  return e;
}

bool
awasm_asg_node_list_eql(awasm_asg_node_list *a, awasm_asg_node_list *b) {
  awasm_asg_nodeql
}

bool
awasm_asg_node_list_find(awasm_asg_node_list *seq, awasm_asg_node *value, uint16_t *index) {

  if(seq->len == 0) return false;

  for(uint16_t i = 0; i < seq->capa; i++) {
    if(!AWASM_ASG_NODE_LIST_DATA(seq)[i].free) {
      if(awasm_asg_node_list_cmp(value, &AWASM_ASG_NODE_LIST_DATA(seq)[i])) {
        if(index != NULL) *index = i;
        return true;
      }
    }
  }
  return false;
}

void
awasm_asg_node_list_destroy(awasm_asg_node_list *seq) {
  awasm_free(seq->data);
}
