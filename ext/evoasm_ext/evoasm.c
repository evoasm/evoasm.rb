#include "evoasm.h"
#include "evoasm-log.h"

void
evoasm_init(int argc, const char **argv, FILE *log_file) {
  evoasm_log_file = log_file;
}
