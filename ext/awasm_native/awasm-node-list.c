#include "awasm-node-list.h"

#include <assert.h>
#include <errno.h>

#include "awasm-alloc.h"

#include "awasm-node.h"


#define AWASM_SEQ_NOT_FREE ((uint32_t)-1)

void
awasm_node_list_clear(awasm_node_list *seq, uint32_t start, uint32_t end) {
  for(uint32_t i = start; i < end - 1; i++) {
    AWASM_SEQ_DATA(seq)[i].free = true;
    AWASM_SEQ_DATA(seq)[i].next_free = i + 1;
  }
  AWASM_SEQ_DATA(seq)[end - 1].next_free = AWASM_SEQ_NOT_FREE;
  AWASM_SEQ_DATA(seq)[end - 1].free = true;

  seq->last_free = end - 1;
}


awasm_node *
awasm_node_list_data(awasm_node_list *seq) {
 return AWASM_SEQ_DATA(seq);
}

awasm_success
awasm_node_list_init(awasm_node_list *seq, uint32_t capa) {

#if 0 > 0
  seq->data = NULL;
  seq->capa = AWASM_SEQ_EMBED_N;
#else
  size_t size = sizeof(awasm_node) * capa;
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

  awasm_node_list_clear(seq, 0, seq->capa);
  return true;
}

static awasm_success
awasm_node_list_grow(awasm_node_list *seq) {
  uint32_t new_capa = seq->capa + seq->capa / 2;

#if 0 > 0
  if(seq->data == NULL) {
    seq->data = malloc(sizeof(awasm_node) * new_capa);
    memcpy(seq->data, seq->_data, sizeof(awasm_node) * seq->capa);
    goto update;
  }
#endif

  {
    size_t size = sizeof(awasm_node) * new_capa;
    awasm_node *new_data = awasm_realloc(seq->data, size);

    if(AWASM_UNLIKELY(new_data == NULL)) {
      awasm_set_error(AWASM_ERROR_TYPE_MEMORY, AWASM_ERROR_CODE_NONE,
          NULL, "Reallocationg buffer of size %zu failed: %s", size, strerror(errno));
      return false;
    }
  }
update:
  seq->first_free = seq->capa;
  awasm_node_list_clear(seq, seq->capa, new_capa);
  seq->capa = new_capa;
  return true;
}

awasm_success
awasm_node_list_push(awasm_node_list *seq, awasm_node **ee) {
  if(seq->first_free == AWASM_SEQ_NOT_FREE) {
    if(!awasm_node_list_grow(seq)) {
      return false;
    }
  }

  {
    awasm_node *entry = &AWASM_SEQ_DATA(seq)[seq->first_free];

    uint32_t index = seq->first_free;

    // used up last free slot
    if(entry->next_free == AWASM_SEQ_NOT_FREE){
      assert(index == seq->last_free);
      seq->last_free = AWASM_SEQ_NOT_FREE;
    }

    seq->first_free = entry->next_free;

    entry->free = false;
    entry->next_free = AWASM_SEQ_NOT_FREE;

    seq->len++;

    *ee = e;
    return true;
  }
}

awasm_node *
awasm_node_list_get(awasm_node_list *seq, uint32_t index) {
  if(index >= seq->capa) {
    return NULL;
  }
  return AWASM_SEQ_DATA(seq)[index].free ? NULL : &AWASM_SEQ_DATA(seq)[index];
}

awasm_node *
awasm_node_list_delete(awasm_node_list *seq, awasm_node *e) {
  e->next_free = seq->first_free;
  e->free = true;

  // only free slot
  if(seq->last_free == AWASM_SEQ_NOT_FREE) {
    seq->last_free = index;
  }

  seq->first_free = index;
  seq->len--;
  return e;
}

bool
awasm_node_list_cmp(awasm_node_list *a, awasm_node_list *b) {
  return false;
}

bool
awasm_node_list_find(awasm_node_list *seq, awasm_node *value, uint32_t *index) {

  if(seq->len == 0) return false;

  for(uint32_t i = 0; i < seq->capa; i++) {
    if(!AWASM_SEQ_DATA(seq)[i].free) {
      if(awasm_node_list_cmp(value, &AWASM_SEQ_DATA(seq)[i])) {
        if(index != NULL) *index = i;
        return true;
      }
    }
  }
  return false;
}

void
awasm_node_list_destroy(awasm_node_list *seq) {
  awasm_free(seq->data);
}
