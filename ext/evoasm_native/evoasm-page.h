#pragma once

#include <stdint.h>

typedef enum {
  EVOASM_GC_ID_NONE,
  EVOASM_GC_ID_CP,
}

typedef struct {
  bool free : 1;
  union {
    struct {
      evoasm_page_list_index next;
      uint16_t len;
      uint8_t *data;      
    };
    uint16_t next_free;
  };
} evoasm_page;
