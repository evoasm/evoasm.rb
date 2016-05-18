#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "awasm-edge.h"


#if 3 > 0
#  define AWASM_SEQ_DATA(seq) (seq->data != NULL ? seq->data : seq->_data)
#else
#  define AWASM_SEQ_DATA(seq) (seq->data)
#endif

typedef struct awasm_edge_set {
  uint32_t capa;
  uint32_t len;
  uint32_t first_free;
  uint32_t last_free;
  awasm_edge *data;

#if 3 > 0
  awasm_edge _data[3];
#endif
} awasm_edge_set;

static inline uint32_t
awasm_edge_set_index(awasm_edge_set *seq, awasm_edge *e) {
  return (uint32_t)(e - AWASM_SEQ_DATA(seq));
}

void awasm_edge_set_clear(awasm_edge_set *seq, uint32_t start, uint32_t end);
awasm_success awasm_edge_set_init(awasm_edge_set *seq, uint32_t capa);
awasm_edge *awasm_edge_set_push(awasm_edge_set *seq, awasm_edge **e);
awasm_edge *awasm_edge_set_get(awasm_edge_set *seq, uint32_t index);
awasm_edge *awasm_edge_set_delete(awasm_edge_set *seq, awasm_edge *e);
void awasm_edge_set_destroy(awasm_edge_set *seq);
awasm_edge * awasm_edge_set_data(awasm_edge_set *seq);
bool awasm_edge_set_find(awasm_edge_set *seq, awasm_edge *value, uint32_t *index);
