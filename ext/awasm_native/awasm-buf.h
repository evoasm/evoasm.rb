#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "awasm-error.h"
#include "awasm-log.h"

typedef enum {
  AWASM_BUF_TYPE_MMAP,
  AWASM_BUF_TYPE_MALLOC,
  AWASM_N_BUF_TYPES
} awasm_buf_type;

typedef struct {
    size_t  capa;
    size_t  pos;
    awasm_buf_type type : 2;
    uint8_t *data;
} awasm_buf;

awasm_success
awasm_buf_init(awasm_buf *buf, awasm_buf_type buf_type, size_t size);

awasm_success
awasm_buf_destroy(awasm_buf *buf);

void
awasm_buf_reset(awasm_buf *buf);

size_t
awasm_buf_append(awasm_buf * restrict dst, awasm_buf * restrict src);

awasm_success
awasm_buf_protect(awasm_buf *buf, int mode);

intptr_t
awasm_buf_exec(awasm_buf *buf);

void
awasm_buf_log(awasm_buf *buf, awasm_log_level log_level);

awasm_success
awasm_buf_clone(awasm_buf * restrict buf, awasm_buf * restrict cloned_buf);

