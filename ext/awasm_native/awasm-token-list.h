#pragma once

#include <stdint.h>
#include "awasm-error.h"

#include "awasm-token.h"


#if 0 > 0
#  define AWASM_SEQ_DATA(seq) (seq->data != NULL ? seq->data : seq->_data)
#else
#  define AWASM_SEQ_DATA(seq) (seq->data)
#endif

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

static inline uint32_t
awasm_token_list_index(awasm_token_list *seq, awasm_token *e) {
  return (uint32_t)(e - AWASM_SEQ_DATA(seq));
}

void awasm_token_list_clear(awasm_token_list *seq, uint32_t start, uint32_t end);
awasm_success awasm_token_list_init(awasm_token_list *seq, uint32_t capa);
awasm_token *awasm_token_list_push(awasm_token_list *seq, awasm_token **e);
awasm_token *awasm_token_list_get(awasm_token_list *seq, uint32_t index);
awasm_token *awasm_token_list_delete(awasm_token_list *seq, awasm_token *e);
void awasm_token_list_destroy(awasm_token_list *seq);
awasm_token * awasm_token_list_data(awasm_token_list *seq);
bool awasm_token_list_find(awasm_token_list *seq, awasm_token *value, uint32_t *index);
