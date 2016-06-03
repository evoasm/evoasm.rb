#pragma once

#include "evoasm-page-list.h"
#include <stdalign.h>

#define EVOASM_HEAP_MAX_COPY_FUNCS 255
#define EVOASM_HEAP_ALIGN (alignof(void *))

typedef struct {
    
} evoasm_gc;

struct evoasm_heap;

typedef void (*evoasm_heap_copy_func)(struct evoasm_heap *heap, evoasm_gc *gc, uint8_t *data);

#include "evoasm-cpgc.h"

typedef struct evoasm_heap {
  evoasm_page_list pages;
  evoasm_heap_copy_func copy_funcs[EVOASM_HEAP_MAX_COPY_FUNCS];
  evoasm_cpgc cpgc;
} evoasm_heap;

typedef struct {
  uint16_t fwd_ptr;
  uint16_t copy_func_idx;
  uint16_t size;
  uint8_t age;
  uint8_t type;
  alignas(EVOASM_HEAP_ALIGN) uint8_t data[];
} evoasm_heap_header;
