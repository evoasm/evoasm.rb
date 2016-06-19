#include <assert.h>
#include <errno.h>

#include "evoasm-page-list.h"
#include "evoasm-alloc.h"

#include "evoasm-page.h"

void
evoasm_page_list_clear(evoasm_page_list *free_list, evoasm_page_list_index start, evoasm_page_list_index end) {
  for(evoasm_page_list_index i = start; i < end - 1; i++) {
    EVOASM_PAGE_LIST_DATA(free_list)[i].free = true;
    EVOASM_PAGE_LIST_DATA(free_list)[i].next_free = i + 1;
  }
  EVOASM_PAGE_LIST_DATA(free_list)[end - 1].next_free = EVOASM_PAGE_LIST_NULL_IDX;
  EVOASM_PAGE_LIST_DATA(free_list)[end - 1].free = true;

  free_list->last_free = end - 1;
}


evoasm_page *
evoasm_page_list_data(evoasm_page_list *free_list) {
 return EVOASM_PAGE_LIST_DATA(free_list);
}

evoasm_success
evoasm_page_list_init(evoasm_page_list *free_list, evoasm_page_list_index capa) {

#if 0 > 0
  free_list->data = NULL;
  free_list->capa = EVOASM_SEQ_EMBED_N;
#else
  size_t size = sizeof(evoasm_page) * capa;
  free_list->data = evoasm_malloc(size);
  if(free_list->data == NULL) {
    evoasm_set_error(EVOASM_ERROR_TYPE_MEMORY, EVOASM_ERROR_CODE_NONE,
        NULL, "Allocationg buffer of size %zu failed: %s", size, strerror(errno));
    return false;
  }
  free_list->capa = capa;
#endif

  free_list->first_free = 0;
  free_list->len = 0;

  evoasm_page_list_clear(free_list, 0, free_list->capa);
  return true;
}

evoasm_success
_evoasm_page_list_grow(evoasm_page_list *free_list) {
  evoasm_page_list_index new_capa = free_list->capa + free_list->capa / 2;

#if 0 > 0
  if(free_list->data == NULL) {
    free_list->data = malloc(sizeof(evoasm_page) * new_capa);
    memcpy(free_list->data, free_list->_data, sizeof(evoasm_page) * free_list->capa);
    goto update;
  }
#endif

  {
    size_t size = sizeof(evoasm_page) * new_capa;
    evoasm_page *new_data = evoasm_realloc(free_list->data, size);

    if(EVOASM_UNLIKELY(new_data == NULL)) {
      evoasm_set_error(EVOASM_ERROR_TYPE_MEMORY, EVOASM_ERROR_CODE_NONE,
          NULL, "Reallocationg buffer of size %zu failed: %s", size, strerror(errno));
      return false;
    }
  }
update:
  free_list->first_free = free_list->capa;
  evoasm_page_list_clear(free_list, free_list->capa, new_capa);
  free_list->capa = new_capa;
  return true;
}

evoasm_page *
evoasm_page_list_delete(evoasm_page_list *free_list, evoasm_page *e) {
  evoasm_page_list_index idx = evoasm_page_list_index(free_list, e);

  e->next_free = free_list->first_free;
  e->free = true;

  // only free slot
  if(free_list->last_free == EVOASM_PAGE_LIST_NULL_IDX) {
    free_list->last_free = idx;
  }

  free_list->first_free = idx;
  free_list->len--;
  return e;
}

bool
evoasm_page_list_eql(evoasm_page_list *a, evoasm_page_list *b) {
  evoasm_pageql
}

bool
evoasm_page_list_find(evoasm_page_list *free_list, evoasm_page *value, evoasm_page_list_index *index) {

  if(free_list->len == 0) return false;

  for(evoasm_page_list_index i = 0; i < free_list->capa; i++) {
    if(!EVOASM_PAGE_LIST_DATA(free_list)[i].free) {
      if(evoasm_page_list_cmp(value, &EVOASM_PAGE_LIST_DATA(free_list)[i])) {
        if(index != NULL) *index = i;
        return true;
      }
    }
  }
  return false;
}

void
evoasm_page_list_destroy(evoasm_page_list *free_list) {
  evoasm_free(free_list->data);
}
