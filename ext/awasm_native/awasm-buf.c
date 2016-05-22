#include <string.h>

#include "awasm-buf.h"
#include "awasm-util.h"
#include "awasm-error.h"
#include "awasm-alloc.h"
#include "awasm-log.h"

AWASM_DECL_LOG_TAG("buf");

static awasm_success
awasm_buf_init_mmap(awasm_buf *buf, size_t size) {
  uint8_t *mem;

  //size = AWASM_ALIGN_UP(size, awasm_page_size());
  mem = awasm_mmap(size, NULL);

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

static awasm_success
awasm_buf_init_malloc(awasm_buf *buf, size_t size) {
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

awasm_success
awasm_buf_init(awasm_buf *buf, awasm_buf_type buf_type, size_t size)
{
  buf->type = buf_type;
  switch(buf_type) {
    case AWASM_BUF_TYPE_MMAP: return awasm_buf_init_mmap(buf, size);
    case AWASM_BUF_TYPE_MALLOC: return awasm_buf_init_malloc(buf, size);
    default: awasm_assert_not_reached();
  }
}

static awasm_success
awasm_buf_destroy_mmap(awasm_buf *buf) {
  return awasm_munmap(buf->data, buf->capa);
}

static awasm_success
awasm_buf_destroy_malloc(awasm_buf *buf) {
  awasm_free(buf->data);
  return true;
}

awasm_success
awasm_buf_destroy(awasm_buf *buf)
{
  switch(buf->type) {
    case AWASM_BUF_TYPE_MMAP: return awasm_buf_destroy_mmap(buf);
    case AWASM_BUF_TYPE_MALLOC: return awasm_buf_destroy_malloc(buf);
    default: awasm_assert_not_reached();
  }
}

void
awasm_buf_reset(awasm_buf *buf) {
  memset(buf->data, 0, buf->pos);
  buf->pos = 0;
}

awasm_success
awasm_buf_protect(awasm_buf *buf, int mode) {
  return awasm_mprot(buf->data, buf->capa, mode);
}

intptr_t
awasm_buf_exec(awasm_buf *buf) {
  intptr_t (*func)(void);
  intptr_t result = 0;
  *(void **) (&func) = buf->data;
  result = func();
  return result;
}

void
awasm_buf_log(awasm_buf *buf, awasm_log_level log_level) {
  unsigned i;

  awasm_log(log_level, AWASM_LOG_TAG, "Awasm::Buffer: capa: %zu, pos: %zu, addr: %p\n", buf->capa, buf->pos, (void *) buf->data);
  for(i = 0; i < buf->pos; i++)
  {
    if (i > 0) awasm_log(log_level, AWASM_LOG_TAG, "   ");
    awasm_log(log_level, AWASM_LOG_TAG, " %02X ", buf->data[i]);
  }
  awasm_log(log_level, AWASM_LOG_TAG, " \n ");
}

size_t
awasm_buf_append(awasm_buf * restrict dst, awasm_buf * restrict src) {
  if(src->pos > dst->capa - dst->pos) {
    return src->pos - (dst->capa - dst->pos);
  }
  memcpy(dst->data + dst->pos, src->data, src->pos);
  dst->pos += src->pos;
  return 0;
}

awasm_success
awasm_buf_clone(awasm_buf * restrict buf, awasm_buf * restrict cloned_buf) {
  if(!awasm_buf_init(cloned_buf, buf->type, buf->capa)) {
    return false;
  }
  awasm_buf_append(cloned_buf, buf);
  return true;
}
