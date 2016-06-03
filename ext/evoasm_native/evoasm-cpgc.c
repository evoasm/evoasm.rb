#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <inttypes.h>

#include "evoasm-cpgc.h"
#include "evoasm-util.h"
#include "evoasm-log.h"
#include "evoasm-page.h"

#define EACH_HEADER_BEGIN(cpgc) \
{                                   \
  uint8_t *data_end_ptr = cpgc->data + cpgc->len; \
  uint8_t * data_ptr = cpgc->data; \
  while(data_ptr < data_end_ptr) {\
    evoasm_cpgc_header *header = (evoasm_cpgc_header *) data_ptr;


#define EACH_HEADER_END(cpgc) \
    data_ptr += header->size; \
  }\
}

EVOASM_DECL_LOG_TAG("cpgc");

evoasm_cpgc_header *
evoasm_cpgc_get_header(uint8_t *ptr)
{
  return (evoasm_cpgc_header *) (ptr - offsetof(evoasm_cpgc_header, data));
}


uint8_t *
evoasm_cpgc_header_data(evoasm_cpgc_header *header)
{
  return header->data;
}

static uint8_t *
evoasm_cpgc_copy_header(evoasm_cpgc *cpgc, evoasm_cpgc_header *header)
{
  if(EVOASM_LIKELY(header->fwd_ptr == 0)) {
    header->fwd_ptr = cpgc->data2 + cpgc->len2;
    evoasm_debug("copying header %p (data: %p, size: %d) to %p", header, header->data, header->size, header->fwd_ptr);
    cpgc->len2 += header->size;
    header = (evoasm_cpgc_header *) memcpy(header->fwd_ptr, header, header->size);

    if(EVOASM_LIKELY(header->copy_func_idx < cpgc->copy_funcs_len))
    {
      (*cpgc->copy_funcs[header->copy_func_idx])(cpgc, header->data);
    }
  }
  else
  {
    evoasm_debug("already copied header %p (%p)", header, header->data);
    header = (evoasm_cpgc_header *) (header->fwd_ptr);
  }
  return header->data;
}

uint8_t *
evoasm_cpgc_copy(evoasm_cpgc *cpgc, uint8_t *ptr)
{
  if(EVOASM_UNLIKELY(ptr == NULL)) return NULL;

  evoasm_cpgc_header *header = evoasm_cpgc_get_header(ptr);
  return evoasm_cpgc_copy_header(cpgc, header);
}


bool
evoasm_cpgc_copy_from_roots(evoasm_cpgc *cpgc, size_t size, uint8_t *roots[], size_t len)
{
  uintptr_t freed;
  bool retval = true;

  if((len == 0 || roots == NULL) && size <= cpgc->size)
  {
    freed = cpgc->len;
    cpgc->len = 0;

    retval = true;
    goto done;
  }

  assert(size >= cpgc->len);

  cpgc->len2 = 0;
  cpgc->data2 = evoasm_mmap(evoasm_page_size(), NULL);
  if(EVOASM_UNLIKELY(cpgc->data2 == NULL))
  {
    evoasm_error("allocating to space failed");

    retval = false;
    goto done;
  }

  for(size_t i = 0; i < len; i++)
  {
    roots[i] = evoasm_cpgc_copy(cpgc, roots[i]);
  }

  freed = cpgc->len - cpgc->len2;
  evoasm_debug("gc len from %zd to %zd", cpgc->len, cpgc->len2);
  assert(cpgc->len >= cpgc->len2);

  free(cpgc->data);
  cpgc->data = cpgc->data2;
  cpgc->data2 = NULL;
  cpgc->size = size;
  cpgc->len = cpgc->len2;
  cpgc->len2 = 0;

  EACH_HEADER_BEGIN(cpgc)
    header->fwd_ptr = 0;
  EACH_HEADER_END(cpgc)

done:
  evoasm_debug("copy gc finished with status %d (freed %" PRIuPTR " bytes)", retval, freed);
  return retval;
}

static bool
evoasm_cpgc_resize(evoasm_cpgc *cpgc, size_t size, uint8_t *roots[], size_t len)
{
  evoasm_debug("resizing from %zd to %zd", cpgc->size, size);
  return evoasm_cpgc_copy_from_roots(cpgc, size, roots, len);
}

void *
evoasm_cpgc_each_header(evoasm_cpgc *cpgc, evoasm_cpgc_each_header_func cb, void *user_data)
{
  EACH_HEADER_BEGIN(cpgc)
    user_data = ((*cb)(header, user_data));
  EACH_HEADER_END(cpgc)
  return user_data;
}

bool
evoasm_cpgc_gc(evoasm_cpgc *cpgc, uint8_t *roots[], size_t len)
{
  size_t size;

  if(cpgc->len >= (cpgc->size / 2 + cpgc->size / 4))
  {
    size = cpgc->size + cpgc->size / 2;
  }
  else
  {
    size = cpgc->size + cpgc->len / 2;
  }
  return evoasm_cpgc_copy_from_roots(cpgc, size, roots, len);
}

uint8_t *
evoasm_cpgc_alloc(evoasm_cpgc *cpgc,
                size_t size,
                uint16_t copy_func_idx,
                uint8_t *roots[],
                size_t roots_len)
{

  size_t new_len;
  size_t total_size = sizeof(evoasm_cpgc_header) + EVOASM_ALIGN_UP(size, EVOASM_CPGC_ALIGN);

  assert(size > 0);
  assert(total_size <= EVOASM_CPGC_MAX_ALLOC_SIZE);

  new_len = cpgc->len + total_size;

  if(EVOASM_UNLIKELY(new_len >= cpgc->size))
  {
    evoasm_debug("new len %zd (before %zd) exceeds size (%zd), resizing...", new_len, cpgc->len, cpgc->size);

    size_t new_size = new_len + (new_len / 2) + (new_len / 4);
    if(EVOASM_UNLIKELY(!evoasm_cpgc_resize(cpgc, new_size, roots, roots_len)))
    {
      return NULL;
    }
    new_len = cpgc->len + total_size;
  }

  evoasm_cpgc_header *header = (evoasm_cpgc_header *)(cpgc->data + cpgc->len);

  assert((uintptr_t)header->data % EVOASM_CPGC_ALIGN == 0);
  assert(((uintptr_t)header->data + size) <= (uintptr_t)cpgc->data + new_len);

  header->fwd_ptr = NULL;
  header->copy_func_idx = copy_func_idx;
  header->size = (uint16_t) total_size;
  header->age = 0;

  assert(header->size > 0);

  evoasm_debug("allocated header %p (%p) of size %d (%zd data)", header, header->data, header->size, size);
  evoasm_debug("len from %zd to %zd , %zd %zd", cpgc->len, new_len, total_size, cpgc->len + total_size);

  cpgc->len = new_len;

  assert((uintptr_t)cpgc->data + new_len == (uintptr_t)header + header->size);
  return header->data;
}

uint16_t
evoasm_cpgc_register_copy_func(evoasm_cpgc *cpgc, evoasm_cpgc_copy_func copy_func)
{
  uint16_t idx = cpgc->copy_funcs_len;

  cpgc->copy_funcs[cpgc->copy_funcs_len++] = copy_func;

  return idx;
}
