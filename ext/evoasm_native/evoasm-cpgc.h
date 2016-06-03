#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <assert.h>

#include "evoasm-heap.h"

typedef enum {
  EVOASM_CPGC_FLAGS_NONE = 0,
} evoasm_cpgc_copy_flags;

#define evoasm_cpgc_flags(cpgc) ((cpgc)->flags)

typedef struct evoasm_cpgc {
  evoasm_heap *heap;
  evoasm_page *page;
  evoasm_page *page2;
  evoasm_cpgc_copy_flags flags;
};


evoasm_cpgc_header *
evoasm_cpgc_get_header(uint8_t *ptr);

uint8_t *
evoasm_cpgc_alloc(evoasm_cpgc *cpgc, size_t size,
                 uint16_t copy_func_idx,
                 uint8_t *roots[], size_t roots_len) EVOASM_MALLOC_ATTRS;

evoasm_success
evoasm_cpgc_init(evoasm_cpgc *cpgc, size_t size, evoasm_cpgc_copy_flags flags);

void
evoasm_cpgc_destroy(evoasm_cpgc *cpgc);

uint8_t *
evoasm_cpgc_header_data(evoasm_cpgc_header *header);

void *
evoasm_cpgc_each_header(evoasm_cpgc *cpgc, evoasm_cpgc_each_header_func cb, void *user_data);

uint8_t *
evoasm_cpgc_copy(evoasm_cpgc *cpgc, uint8_t *ptr);

bool
evoasm_cpgc_gc(evoasm_cpgc *cpgc, uint8_t *roots[], size_t len);

uint16_t
evoasm_cpgc_register_copy_func(evoasm_cpgc *cpgc, evoasm_cpgc_copy_func copy_func);
