#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "gen/awasm-asg-edge.h"

#if 0 > 0
#  define AWASM_ASG_EDGE_LIST_DATA(seq) (seq->data != NULL ? seq->data : seq->_data)
#else
#  define AWASM_ASG_EDGE_LIST_DATA(seq) (seq->data)
#endif

#define AWASM_ASG_EDGE_LIST_NULL_IDX ((uint16_t)-1)

typedef struct awasm_asg_edge_list {
  uint16_t capa;
  uint16_t len;
  uint16_t first_free;
  uint16_t last_free;
  awasm_asg_edge *data;

#if 0 > 0
  awasm_asg_edge _data[0];
#endif
} awasm_asg_edge_list;

static inline uint32_t
awasm_asg_edge_list_index(awasm_asg_edge_list *seq, awasm_asg_edge *e) {
  return (uint32_t)(e - AWASM_ASG_EDGE_LIST_DATA(seq));
}

static inline awasm_asg_edge *
awasm_asg_edge_list_get(awasm_asg_edge_list *seq, uint16_t index) {
#if 0
  if(index >= seq->capa) {
    return NULL;
  }
  return AWASM_ASG_EDGE_LIST_DATA(seq)[index].free ? NULL : &AWASM_ASG_EDGE_LIST_DATA(seq)[index];
#endif
  return &AWASM_ASG_EDGE_LIST_DATA(seq)[index];
}

awasm_success _awasm_asg_edge_list_grow(awasm_asg_edge_list *seq);

static inline awasm_success
awasm_asg_edge_list_push(awasm_asg_edge_list *seq, awasm_asg_edge **ee, uint16_t *ridx) {
  if(seq->first_free == AWASM_ASG_EDGE_LIST_NULL_IDX) {
    if(!_awasm_asg_edge_list_grow(seq)) {
      return false;
    }
  }

  {
    awasm_asg_edge *entry = &AWASM_ASG_EDGE_LIST_DATA(seq)[seq->first_free];

    uint16_t idx = seq->first_free;

    // used up last free slot
    if(entry->next_free == AWASM_ASG_EDGE_LIST_NULL_IDX){
      assert(idx == seq->last_free);
      seq->last_free = AWASM_ASG_EDGE_LIST_NULL_IDX;
    }

    seq->first_free = entry->next_free;

    entry->free = false;
    entry->next_free = AWASM_ASG_EDGE_LIST_NULL_IDX;

    seq->len++;

    *ee = entry;
    if(ridx) {
      *ridx = idx;
    }
    return true;
  }
}

void awasm_asg_edge_list_clear(awasm_asg_edge_list *seq, uint32_t start, uint32_t end);
awasm_success awasm_asg_edge_list_init(awasm_asg_edge_list *seq, uint16_t capa);
awasm_asg_edge *awasm_asg_edge_list_delete(awasm_asg_edge_list *seq, awasm_asg_edge *e);
void awasm_asg_edge_list_destroy(awasm_asg_edge_list *seq);
awasm_asg_edge * awasm_asg_edge_list_data(awasm_asg_edge_list *seq);
