/* vim: set filetype=c: */

#pragma once

#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>
#include <assert.h>
#include <math.h>
#include <string.h>
#include <inttypes.h>

#include "awasm-util.h"
#include "awasm-log.h"
#include "awasm-buf.h"
#include "awasm-alloc.h"
#include "awasm-arch.h"
#include "awasm-error.h"

void
awasm_init(int argc, const char **argv, FILE *log_file);

