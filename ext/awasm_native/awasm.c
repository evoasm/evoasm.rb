#include "awasm.h"
#include "awasm-log.h"

void
awasm_init(int argc, const char **argv, FILE *log_file) {
  awasm_log_file = log_file;
}
