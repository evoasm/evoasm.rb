#pragma once

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdarg.h>
#include <setjmp.h>

#include "awasm-util.h"

#define AWASM_ERROR_MAX_FILENAME_LEN 128
#define AWASM_ERROR_MAX_MSG_LEN 128

#define AWASM_ERROR_HEADER \
  uint16_t type; \
  uint16_t code; \
  uint32_t line; \
  char filename[AWASM_ERROR_MAX_FILENAME_LEN]; \
  char msg[AWASM_ERROR_MAX_MSG_LEN];

typedef enum {
  AWASM_ERROR_CODE_NONE,
  AWASM_N_ERROR_CODES
} awasm_error_code;

typedef enum {
  AWASM_ERROR_TYPE_INVALID,
  AWASM_ERROR_TYPE_ARGUMENT,
  AWASM_ERROR_TYPE_MEMORY,
  AWASM_ERROR_TYPE_ARCH,
} awasm_error_type;

typedef struct {
  uint8_t data[64];
} awasm_error_data;

typedef struct {
  AWASM_ERROR_HEADER
  awasm_error_data data;
} awasm_error;


void
awasm_error_setv(awasm_error *error, unsigned error_type, unsigned error_code,
                 void *error_data, const char *file,
                 unsigned line, const char *format, va_list args);

void
awasm_error_set(awasm_error *error, unsigned error_type, unsigned error_code,
                void *error_data, const char *file,
                unsigned line, const char *format, ...);


extern _Thread_local awasm_error awasm_last_error;

#define AWASM_TRY(label, func, ...) \
  do { if(!func(__VA_ARGS__)) {goto label;} } while(0)

#define awasm_success awasm_check_return bool

#define awasm_set_error(type, code, data, ...) \
  awasm_error_set(&awasm_last_error, (type), (code), (data),\
                   __FILE__, __LINE__, __VA_ARGS__)

#define awasm_assert_not_reached() \
  awasm_assert_not_reached_full(__FILE__, __LINE__)

static inline _Noreturn void awasm_assert_not_reached_full(const char *file, unsigned line) {
  fprintf(stderr, "FATAL: %s:%d should not be reached\n", file, line);
  abort();
}
