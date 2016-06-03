#include "evoasm-heap.h"

evoasm_success
evoasm_heap_init(evoasm_heap *heap) {
  return evoasm_page_list_init(&heap->pages);
}

void
evoasm_heap_destroy(evoasm_heap *heap) {
  evoasm_page_list_destroy(&heap->pages);
}


