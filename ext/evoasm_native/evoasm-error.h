#pragma once

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdarg.h>
#include <setjmp.h>

#include "evoasm-util.h"

#define EVOASM_ERROR_MAX_FILENAME_LEN 128
#define EVOASM_ERROR_MAX_MSG_LEN 128

#define EVOASM_ERROR_HEADER \
  uint16_t type; \
  uint16_t code; \
  uint32_t line; \
  char filename[EVOASM_ERROR_MAX_FILENAME_LEN]; \
  char msg[EVOASM_ERROR_MAX_MSG_LEN];

typedef enum {
  EVOASM_ERROR_CODE_NONE,
  EVOASM_N_ERROR_CODES
} evoasm_error_code;

typedef enum {
  EVOASM_ERROR_TYPE_INVALID,
  EVOASM_ERROR_TYPE_ARGUMENT,
  EVOASM_ERROR_TYPE_MEMORY,
  EVOASM_ERROR_TYPE_ARCH,
  EVOASM_ERROR_TYPE_GRAPH,
} evoasm_error_type;

typedef struct {
  uint8_t data[64];
} evoasm_error_data;

typedef struct {
  EVOASM_ERROR_HEADER
  evoasm_error_data data;
} evoasm_error;


void
evoasm_error_setv(evoasm_error *error, unsigned error_type, unsigned error_code,
                 void *error_data, const char *file,
                 unsigned line, const char *format, va_list args);

void
evoasm_error_set(evoasm_error *error, unsigned error_type, unsigned error_code,
                void *error_data, const char *file,
                unsigned line, const char *format, ...);


extern _Thread_local evoasm_error evoasm_last_error;

#define EVOASM_TRY(label, func, ...) \
  do { if(!func(__VA_ARGS__)) {goto label;} } while(0)

#define evoasm_success evoasm_check_return bool

#define evoasm_set_error(type, code, data, ...) \
  evoasm_error_set(&evoasm_last_error, (type), (code), (data),\
                   __FILE__, __LINE__, __VA_ARGS__)

#define evoasm_assert_not_reached() \
  evoasm_assert_not_reached_full(__FILE__, __LINE__)

static inline _Noreturn void evoasm_assert_not_reached_full(const char *file, unsigned line) {
  fprintf(stderr, "FATAL: %s:%d should not be reached\n", file, line);
  abort();
}
