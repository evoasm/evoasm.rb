#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <inttypes.h>

#include "awasm-ygen.h"
#include "awasm-util.h"

#define EACH_HEADER_BEGIN(ygen) \
{                                   \
  uint8_t *data_end_ptr = ygen->data + ygen->cur; \
  uint8_t * data_ptr = ygen->data; \
  while(data_ptr < data_end_ptr) {\
    awasm_ygen_header *header = (awasm_ygen_header *) data_ptr;


#define EACH_HEADER_END(ygen) \
    data_ptr += header->size; \
  }\
}

AWASM_DECL_LOG_TAG("ygen");

static void *
awasm_ygen_alloc_page(void *p, size_t size) {
  return awasm_mmap(NULL, size);
}

static awasm_success
awasm_ygen_free_page(void *p, size_t size) {
  return awasm_munmap(p, size);
}

awasm_success
awasm_ygen_init(awasm_ygen *ygen, size_t size, awasm_ygen_copy_flags flags)
{
  assert(size > 0);

  ygen->data = awasm_ygen_alloc_page(NULL, size);
  if(ygen->data == NULL) {
    return false;
  }
  ygen->cur = 0;
  ygen->cur2 = 0;
  ygen->data2 = NULL;
  ygen->size = ygen->data != NULL ? size : 0;
  ygen->flags = flags;
  ygen->copy_funcs_cur = 0;
}

void
awasm_ygen_destroy(awasm_ygen *ygen)
{
  if(ygen->data != NULL)
  {
    free(ygen->data);
  }
}

awasm_ygen_header *
awasm_ygen_get_header(uint8_t *ptr)
{
  return (awasm_ygen_header *) (ptr - offsetof(awasm_ygen_header, data));
}


uint8_t *
awasm_ygen_header_data(awasm_ygen_header *header)
{
  return header->data;
}

static uint8_t *
awasm_ygen_copy_header(awasm_ygen *ygen, awasm_ygen_header *header)
{
  if(likely(header->fwd_ptr == NULL))
  {
    header->fwd_ptr = ygen->data2 + ygen->cur2;
    awasm_debug("copying header %p (data: %p, size: %d) to %p", header, header->data, header->size, header->fwd_ptr);
    ygen->cur2 += header->size;
    header = (awasm_ygen_header *) memcpy(header->fwd_ptr, header, header->size);

    if(likely(header->copy_func_idx < ygen->copy_funcs_cur))
    {
      (*ygen->copy_funcs[header->copy_func_idx])(ygen, header->data);
    }
  }
  else
  {
    awasm_debug("already copied header %p (%p)", header, header->data);
    header = (awasm_ygen_header *) (header->fwd_ptr);
  }
  return header->data;
}

uint8_t *
awasm_ygen_copy(awasm_ygen *ygen, uint8_t *ptr)
{
  if(AWASM_UNLIKELY(ptr == NULL)) return NULL;

  awasm_ygen_header *header = awasm_ygen_get_header(ptr);
  return awasm_ygen_copy_header(ygen, header);
}


bool
awasm_ygen_copy_from_roots(awasm_ygen *ygen, size_t size, uint8_t *roots[], size_t len)
{
  uintptr_t freed;
  bool retval = true;

  if((len == 0 || roots == NULL) && size <= ygen->size)
  {
    freed = ygen->cur;
    ygen->cur = 0;

    retval = true;
    goto done;
  }

  assert(size >= ygen->cur);

  ygen->cur2 = 0;
  ygen->data2 = aligned_alloc(AWASM_YGEN_ALIGN, size);
  if(unlikely(ygen->data2 == NULL))
  {
    awasm_error("allocating to space failed");

    retval = false;
    goto done;
  }

  for(size_t i = 0; i < len; i++)
  {
    roots[i] = awasm_ygen_copy(ygen, roots[i]);
  }

  freed = ygen->cur - ygen->cur2;
  awasm_debug("gc cur from %zd to %zd", ygen->cur, ygen->cur2);
  assert(ygen->cur >= ygen->cur2);

  free(ygen->data);
  ygen->data = ygen->data2;
  ygen->data2 = NULL;
  ygen->size = size;
  ygen->cur = ygen->cur2;
  ygen->cur2 = 0;

  EACH_HEADER_BEGIN(ygen)
    header->fwd_ptr = NULL;
  EACH_HEADER_END(ygen)

done:
  awasm_debug("copy gc finished with status %d (freed %" PRIuPTR " bytes)", retval, freed);
  return retval;
}

static bool
awasm_ygen_resize(awasm_ygen *ygen, size_t size, uint8_t *roots[], size_t len)
{
  awasm_debug("resizing from %zd to %zd", ygen->size, size);
  return awasm_ygen_copy_from_roots(ygen, size, roots, len);
}

void *
awasm_ygen_each_header(awasm_ygen *ygen, awasm_ygen_each_header_func_t cb, void *user_data)
{
  EACH_HEADER_BEGIN(ygen)
    user_data = ((*cb)(header, user_data));
  EACH_HEADER_END(ygen)
  return user_data;
}

bool
awasm_ygen_gc(awasm_ygen *ygen, uint8_t *roots[], size_t len)
{
  size_t size;

  if(ygen->cur >= (ygen->size / 2 + ygen->size / 4))
  {
    size = ygen->size + ygen->size / 2;
  }
  else
  {
    size = ygen->size + ygen->cur / 2;
  }
  return awasm_ygen_copy_from_roots(ygen, size, roots, len);
}

uint8_t *
awasm_ygen_alloc(awasm_ygen *ygen,
                size_t size,
                uint16_t copy_func_idx,
                uint8_t *roots[],
                size_t roots_len)
{

  size_t new_cur;
  size_t total_size = sizeof(awasm_ygen_header) + AWASM_ALIGN(size, AWASM_YGEN_ALIGN);

  assert(size > 0);
  assert(total_size <= AWASM_YGEN_MAX_ALLOC_SIZE);

  new_cur = ygen->cur + total_size;

  if(unlikely(new_cur >= ygen->size))
  {
    awasm_debug("new cur %zd (before %zd) exceeds size (%zd), resizing...", new_cur, ygen->cur, ygen->size);

    size_t new_size = new_cur + (new_cur / 2) + (new_cur / 4);
    if(unlikely(!awasm_ygen_resize(ygen, new_size, roots, roots_len)))
    {
      return NULL;
    }
    new_cur = ygen->cur + total_size;
  }

  awasm_ygen_header *header = (awasm_ygen_header *)(ygen->data + ygen->cur);

  assert((uintptr_t)header->data % AWASM_YGEN_ALIGN == 0);
  assert(((uintptr_t)header->data + size) <= (uintptr_t)ygen->data + new_cur);

  header->fwd_ptr = NULL;
  header->copy_func_idx = copy_func_idx;
  header->size = (uint16_t) total_size;
  header->age = 0;

  assert(header->size > 0);

  awasm_debug("allocated header %p (%p) of size %d (%zd data)", header, header->data, header->size, size);
  awasm_debug("cur from %zd to %zd , %zd %zd", ygen->cur, new_cur, total_size, ygen->cur + total_size);

  ygen->cur = new_cur;

  assert((uintptr_t)ygen->data + new_cur == (uintptr_t)header + header->size);
  return header->data;
}

uint16_t
awasm_ygen_register_copy_func(awasm_ygen *ygen, awasm_ygen_copy_func copy_func)
{
  uint16_t idx = ygen->copy_funcs_cur;

  ygen->copy_funcs[ygen->copy_funcs_cur++] = copy_func;

  return idx;
}
