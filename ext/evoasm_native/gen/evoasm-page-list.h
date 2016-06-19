#pragma once

#include <stdint.h>
#include "evoasm-error.h"

#include "evoasm-page.h"

#if 0 > 0
#  define EVOASM_PAGE_LIST_DATA(free_list) (free_list->data != NULL ? free_list->data : free_list->_data)
#else
#  define EVOASM_PAGE_LIST_DATA(free_list) (free_list->data)
#endif

#define EVOASM_PAGE_LIST_NULL_IDX ((uint32_t)-1)

typedef uint32_t evoasm_page_list_index;

typedef struct evoasm_page_list {
  evoasm_page_list_index capa;
  evoasm_page_list_index len;
  evoasm_page_list_index first_free;
  evoasm_page_list_index last_free;
  evoasm_page *data;

#if 0 > 0
  evoasm_page _data[0];
#endif
} evoasm_page_list;

static inline uint32_t
evoasm_page_list_get_index(evoasm_page_list *free_list, evoasm_page *e) {
  return (uint32_t)(e - EVOASM_PAGE_LIST_DATA(free_list));
}

static inline evoasm_page *
evoasm_page_list_get(evoasm_page_list *free_list, evoasm_page_list_index index) {
#if 0
  if(index >= free_list->capa) {
    return NULL;
  }
  return EVOASM_PAGE_LIST_DATA(free_list)[index].free ? NULL : &EVOASM_PAGE_LIST_DATA(free_list)[index];
#endif
  return &EVOASM_PAGE_LIST_DATA(free_list)[index];
}

evoasm_success _evoasm_page_list_grow(evoasm_page_list *free_list);

static inline evoasm_success
evoasm_page_list_push(evoasm_page_list *free_list, evoasm_page **ee, evoasm_page_list_index *ridx) {
  if(free_list->first_free == EVOASM_PAGE_LIST_NULL_IDX) {
    if(!_evoasm_page_list_grow(free_list)) {
      return false;
    }
  }

  {
    evoasm_page *entry = &EVOASM_PAGE_LIST_DATA(free_list)[free_list->first_free];

    evoasm_page_list_index idx = free_list->first_free;

    // used up last free slot
    if(entry->next_free == EVOASM_PAGE_LIST_NULL_IDX){
      assert(idx == free_list->last_free);
      free_list->last_free = EVOASM_PAGE_LIST_NULL_IDX;
    }

    free_list->first_free = entry->next_free;

    entry->free = false;
    entry->next_free = EVOASM_PAGE_LIST_NULL_IDX;

    free_list->len++;

    *ee = entry;
    if(ridx) {
      *ridx = idx;
    }
    return true;
  }
}

void evoasm_page_list_clear(evoasm_page_list *free_list, uint32_t start, uint32_t end);
evoasm_success evoasm_page_list_init(evoasm_page_list *free_list, evoasm_page_list_index capa);
evoasm_page *evoasm_page_list_delete(evoasm_page_list *free_list, evoasm_page *e);
void evoasm_page_list_destroy(evoasm_page_list *free_list);
evoasm_page * evoasm_page_list_data(evoasm_page_list *free_list);
