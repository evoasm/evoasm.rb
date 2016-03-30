#include "awasm-error.h"

_Thread_local awasm_error awasm_last_error;

void
awasm_error_setv(awasm_error *error, unsigned error_type, unsigned error_code,
                 void *error_data, const char *file,
                 unsigned line, const char *format, va_list args) {

  error->type = (uint16_t) error_type;
  error->code = (uint16_t) error_code;
  error->line = line;
  strncpy(error->filename, file, AWASM_ERROR_MAX_FILENAME_LEN);
  vsnprintf(error->msg, AWASM_ERROR_MAX_MSG_LEN, format, args);

  if(error_data != NULL) {
    memcpy(&error->data, error_data, sizeof(awasm_error_data));
  }
}

void
awasm_error_set(awasm_error *error, unsigned error_type, unsigned error_code,
                void *error_data, const char *file,
                unsigned line, const char *format, ...) {
  va_list args;
  va_start(args, format);
  awasm_error_setv(error, error_type, error_code,
                   error_data, file, line,
                   format, args);
  va_end(args);
}
