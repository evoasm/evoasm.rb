#include <stdbool.h>
#include <stdint.h>
#include <errno.h>

#include "awasm-sym.h"
#include "awasm-error.h"
#include "awasm-alloc.h"

awasm_success
awasm_sym_tbl_init(awasm_sym_tbl *tbl, uint32_t capa) {
  char *data = awasm_malloc(sizeof(char) * capa);
  if(data == NULL) {
    return false;
  }

  tbl->capa = capa;
  tbl->data = data;
  tbl->len = 0;

  return true;
}

awasm_success
awasm_sym_tbl_get(awasm_sym_tbl *tbl, const char *key, uint32_t len, awasm_sym *sym) {
  unsigned i, j;
  /* Use matching algorithm or at least vectorize */
  for(i = 0; i < tbl->len; i++) {
    if(tbl->data[i] == key[0] &&
       i + len + 1 /* separator char */ < tbl->len) {
      for(j = 1; j < len; j++) {
        if(tbl->data[i + j] != key[j]) {
          goto next;
        }
      }
      if(tbl->data[j + 1] == '\0') {
        *sym = (awasm_sym) i;
        return true;
      }
    }
next:;
  }

  if(tbl->len + len + 1 > tbl->capa) {
    size_t new_capa = (size_t)tbl->capa * 2;
    char *new_data = awasm_realloc(tbl->data, new_capa);
    if(new_data == NULL) {
      awasm_set_error(AWASM_ERROR_TYPE_MEMORY, AWASM_ERROR_CODE_NONE,
        NULL, "Resizing symbol table from %zu to %zu failed: %s", tbl->capa, new_capa, strerror(errno));
      return false;
    }
  }

  memcpy(tbl->data + tbl->len, key, sizeof(char) * len);
  tbl->data[tbl->len + len + 1] = '\0';

  *sym = tbl->len;
  tbl->len += len + 1;

  return true;
}
