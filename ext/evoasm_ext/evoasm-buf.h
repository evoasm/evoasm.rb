#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "evoasm-error.h"
#include "evoasm-log.h"

typedef enum {
  EVOASM_BUF_TYPE_MMAP,
  EVOASM_BUF_TYPE_MALLOC,
  EVOASM_N_BUF_TYPES
} evoasm_buf_type;

typedef struct {
    size_t  capa;
    size_t  pos;
    evoasm_buf_type type : 2;
    uint8_t *data;
} evoasm_buf;

evoasm_success
evoasm_buf_init(evoasm_buf *buf, evoasm_buf_type buf_type, size_t size);

evoasm_success
evoasm_buf_destroy(evoasm_buf *buf);

void
evoasm_buf_reset(evoasm_buf *buf);

size_t
evoasm_buf_append(evoasm_buf * restrict dst, evoasm_buf * restrict src);

evoasm_success
evoasm_buf_protect(evoasm_buf *buf, int mode);

intptr_t
evoasm_buf_exec(evoasm_buf *buf);

void
evoasm_buf_log(evoasm_buf *buf, evoasm_log_level log_level);

evoasm_success
evoasm_buf_clone(evoasm_buf * restrict buf, evoasm_buf * restrict cloned_buf);

