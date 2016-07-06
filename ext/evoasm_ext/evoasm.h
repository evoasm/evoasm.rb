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

#include "evoasm-util.h"
#include "evoasm-log.h"
#include "evoasm-buf.h"
#include "evoasm-alloc.h"
#include "evoasm-arch.h"
#include "evoasm-error.h"

void
evoasm_init(int argc, const char **argv, FILE *log_file);

