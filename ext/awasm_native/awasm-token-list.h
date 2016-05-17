#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "awasm-token.h"


typedef struct awasm_token_list {
  uint32_t capa;
  uint32_t len;
  uint32_t first_free;
  uint32_t last_free;
  awasm_token *data;

#if 0 > 0
  awasm_token _data[0];
#endif
} awasm_token_list;

void awasm_token_list_clear(awasm_token_list *seq, uint32_t start, uint32_t end);
awasm_success awasm_token_list_init(awasm_token_list *seq, uint32_t capa);
awasm_token *awasm_token_list_push(awasm_token_list *seq, uint32_t *index_);
awasm_token *awasm_token_list_get(awasm_token_list *seq, uint32_t index);
awasm_token *awasm_token_list_delete_at(awasm_token_list *seq, uint32_t index);
