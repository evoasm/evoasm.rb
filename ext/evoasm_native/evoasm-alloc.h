#pragma once

#if defined (__unix__) || (defined (__APPLE__) && defined (__MACH__))
#  if !defined(_DEFAULT_SOURCE)
#    define _DEFAULT_SOURCE
#  endif
#  include <unistd.h>
#  include <sys/mman.h>
#  if !defined(MAP_ANONYMOUS) && defined(MAP_ANON)
#    define MAP_ANONYMOUS MAP_ANON
#  endif
#endif

#include <string.h>
#include <alloca.h>

#if defined(_WIN32)
#  include <malloc.h>
#endif

#include "evoasm-error.h"

#ifdef __GNUC__
#  define EVOASM_MALLOC_ATTRS  __attribute__((malloc))
#  define EVOASM_CALLOC_ATTRS  __attribute__((malloc))
#  define EVOASM_REALLOC_ATTRS __attribute__((malloc))
#else
#  define EVOASM_MALLOC_ATTRS
#  define EVOASM_CALLOC_ATTRS
#  define EVOASM_REALLOC_ATTRS
#endif

#if defined(_WIN32)
#define EVOASM_MPROT_RW PAGE_READWRITE
#define EVOASM_MPROT_RX PAGE_EXECUTE_READ
#define EVOASM_MPROT_RWX PAGE_EXECUTE_READWRITE
#elif defined(_POSIX_VERSION)
#define EVOASM_MPROT_RW (PROT_READ|PROT_WRITE)
#define EVOASM_MPROT_RX (PROT_READ|PROT_EXEC)
#define EVOASM_MPROT_RWX (PROT_READ|PROT_WRITE|PROT_EXEC)
#else
#error
#endif

void *evoasm_malloc(size_t) EVOASM_MALLOC_ATTRS;
void *evoasm_calloc(size_t, size_t) EVOASM_CALLOC_ATTRS;
void *evoasm_realloc(void *, size_t) EVOASM_REALLOC_ATTRS;
void evoasm_free(void *);

void *evoasm_mmap(size_t size, void *p);
evoasm_success evoasm_munmap(void *p, size_t size);
evoasm_success evoasm_mprot(void *p, size_t size, int mode);
long evoasm_page_size();

static inline void *
evoasm_alloca(size_t size) {
#if defined(_WIN32)
  return _malloca(size);
#else
  return alloca(size);
#endif
}
