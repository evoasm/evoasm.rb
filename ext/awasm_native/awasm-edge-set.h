#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "awasm-edge.h"


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

void awasm_edge_set_clear(awasm_edge_set *seq, uint32_t start, uint32_t end);
awasm_success awasm_edge_set_init(awasm_edge_set *seq, uint32_t capa);
awasm_edge *awasm_edge_set_push(awasm_edge_set *seq, uint32_t *index_);
awasm_edge *awasm_edge_set_get(awasm_edge_set *seq, uint32_t index);
awasm_edge *awasm_edge_set_delete_at(awasm_edge_set *seq, uint32_t index);
