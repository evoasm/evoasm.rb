#define _DEFAULT_SOURCE

#if defined (__unix__) || (defined (__APPLE__) && defined (__MACH__))
#  include <unistd.h>
#  include <sys/mman.h>

#  if !defined(MAP_ANONYMOUS) && defined(MAP_ANON)
#    define MAP_ANONYMOUS MAP_ANON
#  endif
#endif

#include <string.h>
#include "awasm-error.h"

#ifdef __GNUC__
#  define AWASM_MALLOC_ATTRS  __attribute__((malloc))
#  define AWASM_CALLOC_ATTRS  __attribute__((malloc))
#  define AWASM_REALLOC_ATTRS __attribute__((malloc))
#else
#  define AWASM_MALLOC_ATTRS
#  define AWASM_CALLOC_ATTRS
#  define AWASM_REALLOC_ATTRS
#endif

#if defined(_WIN32)
#define AWASM_MPROT_RW PAGE_READWRITE
#define AWASM_MPROT_RX PAGE_EXECUTE_READ
#define AWASM_MPROT_RWX PAGE_EXECUTE_READWRITE
#elif defined(_POSIX_VERSION)
#define AWASM_MPROT_RW (PROT_READ|PROT_WRITE)
#define AWASM_MPROT_RX (PROT_READ|PROT_EXEC)
#define AWASM_MPROT_RWX (PROT_READ|PROT_WRITE|PROT_EXEC)
#else
#error
#endif

void *awasm_malloc(size_t) AWASM_MALLOC_ATTRS;
void *awasm_calloc(size_t, size_t) AWASM_CALLOC_ATTRS;
void *awasm_realloc(void *, size_t) AWASM_REALLOC_ATTRS;
void awasm_free(void *);

void *awasm_mmap(size_t size, void *p);
awasm_success awasm_munmap(void *p, size_t size);
awasm_success awasm_mprot(void *p, size_t size, int mode);
long awasm_page_size();

