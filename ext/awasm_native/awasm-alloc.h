#include <string.h>

#ifdef __GNUC__
#  define AWASM_MALLOC_ATTRS  __attribute__((malloc))
#  define AWASM_CALLOC_ATTRS  __attribute__((malloc))
#  define AWASM_REALLOC_ATTRS __attribute__((malloc))
#else
#  define AWASM_MALLOC_ATTRS
#  define AWASM_CALLOC_ATTRS
#  define AWASM_REALLOC_ATTRS
#endif
extern void *awasm_malloc(size_t) AWASM_MALLOC_ATTRS;
extern void *awasm_calloc(size_t, size_t) AWASM_CALLOC_ATTRS;
extern void *awasm_realloc(void *, size_t) AWASM_REALLOC_ATTRS;
extern void awasm_free(void *);

