#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <assert.h>
#include <stdalign.h>

#define AWASM_YGEN_ALIGN (alignof(void *))
#define AWASM_YGEN_MAX_COPY_FUNCS 255
#define AWASM_YGEN_MAX_ALLOC_SIZE UINT16_MAX

typedef enum {
  AWASM_YGEN_FLAGS_NONE = 0,
} awasm_ygen_copy_flags;


#define awasm_ygen_flags(ygen) ((ygen)->flags)
#define awasm_ygen_size(ygen) ((ygen)->size)
#define awasm_ygen_cur(ygen) ((ygen)->cur)

typedef struct awasm_ygen_s awasm_ygen;

typedef void (*awasm_ygen_copy_func)(awasm_ygen *ygen, uint8_t *data);

struct awasm_ygen_s {
  size_t cur;
  size_t cur2;
  size_t size;
  uint8_t *data;
  uint8_t *data2;
  awasm_ygen_copy_flags flags;
  uint16_t copy_funcs_cur;
  awasm_ygen_copy_func copy_funcs[AWASM_YGEN_MAX_COPY_FUNCS];
};

typedef struct {
  uint8_t *fwd_ptr;
  uint16_t copy_func_idx;
  uint16_t size;
  uint16_t age;
  alignas(AWASM_YGEN_ALIGN) uint8_t data[];
} awasm_ygen_header;


typedef void * (*awasm_ygen_each_header_func_t)(awasm_ygen_header *header,
                                            void *user_data);

awasm_ygen_header *
awasm_ygen_get_header(uint8_t *ptr);

uint8_t *
awasm_ygen_alloc(awasm_ygen *ygen, size_t size,
               uint16_t copy_func_idx,
               uint8_t *roots[], size_t roots_len)
               __attribute__((malloc)) __attribute__((alloc_size(2)));

void
awasm_ygen_init(awasm_ygen *ygen, size_t size, awasm_ygen_copy_flags flags);

void
awasm_ygen_destroy(awasm_ygen *ygen);

uint8_t *
awasm_ygen_header_data(awasm_ygen_header *header);

void *
awasm_ygen_each_header(awasm_ygen *ygen, awasm_ygen_each_header_func_t cb, void *user_data);

uint8_t *
awasm_ygen_copy(awasm_ygen *ygen, uint8_t *ptr);

bool
awasm_ygen_gc(awasm_ygen *ygen, uint8_t *roots[], size_t len);

uint16_t
awasm_ygen_register_copy_func(awasm_ygen *ygen, awasm_ygen_copy_func copy_func);
