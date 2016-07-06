#include <string.h>

#include "evoasm-buf.h"
#include "evoasm-util.h"
#include "evoasm-error.h"
#include "evoasm-alloc.h"
#include "evoasm-log.h"

EVOASM_DECL_LOG_TAG("buf")

static evoasm_success
evoasm_buf_init_mmap(evoasm_buf *buf, size_t size) {
  uint8_t *mem;

  //size = EVOASM_ALIGN_UP(size, evoasm_page_size());
  mem = evoasm_mmap(size, NULL);

  if(mem) {
    buf->capa = size;
    buf->data = mem;
    buf->pos = 0;
    return true;
  }
  else {
    return false;
  }
}

static evoasm_success
evoasm_buf_init_malloc(evoasm_buf *buf, size_t size) {
  uint8_t *mem;

  mem = malloc(size);

  if(mem) {
    buf->capa = size;
    buf->data = mem;
    buf->pos = 0;
    return true;
  }
  else {
    return false;
  }
}

evoasm_success
evoasm_buf_init(evoasm_buf *buf, evoasm_buf_type buf_type, size_t size)
{
  buf->type = buf_type;
  switch(buf_type) {
    case EVOASM_BUF_TYPE_MMAP: return evoasm_buf_init_mmap(buf, size);
    case EVOASM_BUF_TYPE_MALLOC: return evoasm_buf_init_malloc(buf, size);
    default: evoasm_assert_not_reached();
  }
}

static evoasm_success
evoasm_buf_destroy_mmap(evoasm_buf *buf) {
  return evoasm_munmap(buf->data, buf->capa);
}

static evoasm_success
evoasm_buf_destroy_malloc(evoasm_buf *buf) {
  evoasm_free(buf->data);
  return true;
}

evoasm_success
evoasm_buf_destroy(evoasm_buf *buf)
{
  switch(buf->type) {
    case EVOASM_BUF_TYPE_MMAP: return evoasm_buf_destroy_mmap(buf);
    case EVOASM_BUF_TYPE_MALLOC: return evoasm_buf_destroy_malloc(buf);
    default: evoasm_assert_not_reached();
  }
}

void
evoasm_buf_reset(evoasm_buf *buf) {
  memset(buf->data, 0, buf->pos);
  buf->pos = 0;
}

evoasm_success
evoasm_buf_protect(evoasm_buf *buf, int mode) {
  return evoasm_mprot(buf->data, buf->capa, mode);
}

intptr_t
evoasm_buf_exec(evoasm_buf *buf) {
  intptr_t (*func)(void);
  intptr_t result = 0;
  *(void **) (&func) = buf->data;
  result = func();
  return result;
}

void
evoasm_buf_log(evoasm_buf *buf, evoasm_log_level log_level) {
  unsigned i;

  evoasm_log(log_level, EVOASM_LOG_TAG, "Evoasm::Buffer: capa: %zu, pos: %zu, addr: %p\n", buf->capa, buf->pos, (void *) buf->data);
  for(i = 0; i < buf->pos; i++)
  {
    if (i > 0) evoasm_log(log_level, EVOASM_LOG_TAG, "   ");
    evoasm_log(log_level, EVOASM_LOG_TAG, " %02X ", buf->data[i]);
  }
  evoasm_log(log_level, EVOASM_LOG_TAG, " \n ");
}

size_t
evoasm_buf_append(evoasm_buf * restrict dst, evoasm_buf * restrict src) {
  size_t free = dst->capa - dst->pos;
  if(src->pos > free) {
    evoasm_set_error(EVOASM_ERROR_TYPE_ARGUMENT, EVOASM_ERROR_CODE_NONE,
      NULL, "buffer does not fit (need %zu bytes but only %zu free)", src->pos, free);
    return src->pos - (dst->capa - dst->pos);
  }
  memcpy(dst->data + dst->pos, src->data, src->pos);
  dst->pos += src->pos;
  return 0;
}

evoasm_success
evoasm_buf_clone(evoasm_buf * restrict buf, evoasm_buf * restrict cloned_buf) {
  if(!evoasm_buf_init(cloned_buf, buf->type, buf->capa)) {
    return false;
  }
  return evoasm_buf_append(cloned_buf, buf) == 0;
}
