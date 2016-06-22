#pragma once

#include <stdint.h>
#include <stdlib.h>

#include "evoasm.h"
#include "evoasm-buf.h"
#include "evoasm-x64.h"

typedef double evoasm_fitness;
typedef uint8_t evoasm_program_size;

#define EVOASM_KERNEL_SIZE_MAX UINT8_MAX
typedef uint8_t evoasm_kernel_size;

typedef enum {
  EVOASM_EXAMPLE_TYPE_I64,
  EVOASM_EXAMPLE_TYPE_U64,
  EVOASM_EXAMPLE_TYPE_F64,
} evoasm_example_type;

typedef struct {
  union {
    double f64;
    int64_t i64;
    uint64_t u64;
  };
} evoasm_example_val;

#define EVOASM_PROGRAM_IO_MAX_ARITY 8

typedef struct {
  uint8_t arity;
  uint16_t len;
  evoasm_example_val *vals;
  evoasm_example_type types[EVOASM_PROGRAM_IO_MAX_ARITY];
  evoasm_reg_id regs[EVOASM_PROGRAM_IO_MAX_ARITY];
} evoasm_program_io;

#define EVOASM_PROGRAM_OUTPUT_MAX_ARITY EVOASM_PROGRAM_IO_MAX_ARITY
#define EVOASM_PROGRAM_INPUT_MAX_ARITY EVOASM_PROGRAM_IO_MAX_ARITY
typedef evoasm_program_io evoasm_program_output;
typedef evoasm_program_io evoasm_program_input;

#define EVOASM_PROGRAM_IO_N(program_io) ((uint16_t)((program_io)->len / (program_io)->arity))
#define EVOASM_PROGRAM_INPUT_N(program_input) EVOASM_PROGRAM_IO_N((evoasm_program_io *)program_input)
#define EVOASM_PROGRAM_OUTPUT_N(program_output) EVOASM_PROGRAM_IO_N((evoasm_program_io *)program_output)

typedef struct {
  evoasm_inst *inst;
  evoasm_arch_params_bitmap set_params;
  evoasm_arch_param_val param_vals[EVOASM_ARCH_MAX_PARAMS];
} evoasm_kernel_param;

typedef struct {
  evoasm_kernel_size size;
  /* kernel executed next (jumped to)
   * Kernel terminates if EVOASM_KERNEL_SIZE_MAX 
   */
  evoasm_kernel_size next;
  evoasm_kernel_param params[];
} evoasm_kernel_params;

typedef struct {
  evoasm_program_size size;
  evoasm_kernel_params kernel_params[];
} evoasm_program_params;

#define EVOASM_KERNEL_MAX_OUTPUT_REGS 254
#define EVOASM_KERNEL_MAX_INPUT_REGS 254
#define EVOASM_PROGRAM_MAX_SIZE 64

typedef struct {
  evoasm_kernel_params *params;
  evoasm_reg output_regs[EVOASM_KERNEL_MAX_OUTPUT_REGS];
  evoasm_reg input_regs[EVOASM_KERNEL_MAX_INPUT_REGS];
  uint_fast8_t n_output_regs;
  uint_fast8_t n_input_regs;  
} evoasm_kernel;

typedef struct {
  evoasm_arch *arch;
  evoasm_buf *buf;
  evoasm_buf *body_buf;
  uint32_t index;
  bool reset_rflags : 1;
  bool need_emit    : 1;

  void *_signal_ctx;
  uint32_t exception_mask;

  uint8_t in_arity;
  uint8_t out_arity;
  evoasm_example_type types[EVOASM_PROGRAM_OUTPUT_MAX_ARITY];
  evoasm_example_val *output_vals;

  evoasm_kernel kernels[EVOASM_PROGRAM_MAX_SIZE];
  evoasm_program_input _input;
  evoasm_program_output _output;
  uint_fast8_t *_matching;
  evoasm_kernel_size term_kernel_idx;
} evoasm_program;

#define EVOASM_SEARCH_ELITE_SIZE 4

typedef struct {
  evoasm_prng64 prng64;
  evoasm_prng32 prng32;
  evoasm_fitness best_fitness;
  evoasm_buf buf;
  evoasm_buf body_buf;

  uint32_t elite[EVOASM_SEARCH_ELITE_SIZE];
  uint8_t elite_pos;
  uint_fast8_t *matching;
  evoasm_example_val *output_vals;
  evoasm_fitness *fitnesses;
  unsigned char *programs;
  unsigned char *programs_main;
  unsigned char *programs_swap;
  unsigned char *programs_aux;
} evoasm_population;

#define EVOASM_EXAMPLES_MAX_ARITY 8
typedef struct {
  evoasm_example_type types[EVOASM_EXAMPLES_MAX_ARITY];
  uint16_t len;
  evoasm_example_val *vals;
  uint8_t in_arity;
  uint8_t out_arity;
} evoasm_examples;

typedef struct {
  evoasm_inst **insts;
  evoasm_program_size min_program_size;
  evoasm_program_size max_program_size;
  evoasm_program_size min_kernel_size;
  evoasm_program_size max_kernel_size;
  
  uint16_t insts_len;
  uint8_t params_len;
  uint32_t pop_size;
  uint32_t mutation_rate;
  evoasm_program_input program_input;
  evoasm_program_output program_output;
  evoasm_arch_param_id *params;
  evoasm_prng64_seed seed64;
  evoasm_prng32_seed seed32;
  evoasm_domain *domains[EVOASM_ARCH_MAX_PARAMS];

} evoasm_search_params;

typedef struct {
  evoasm_arch *arch;
  evoasm_population pop;
  evoasm_search_params params;
  evoasm_domain *domains;
} evoasm_search;

bool
evoasm_search_init(evoasm_search *search,
                   evoasm_arch *arch, evoasm_search_params *params);

bool
evoasm_search_destroy(evoasm_search *search);

typedef bool (*evoasm_search_result_func)(evoasm_program *program,
                                         evoasm_fitness fitness, void *user_data);

void
evoasm_search_start(evoasm_search *search, evoasm_fitness min_fitness,
                   evoasm_search_result_func func, void *user_data);

bool
evoasm_program_run(evoasm_program *program,
                  evoasm_program_input *input,
                  evoasm_program_output *output);

void
evoasm_program_io_destroy(evoasm_program_io *program_io);

evoasm_success
evoasm_program_eliminate_introns(evoasm_program *program);

#define evoasm_program_output_destroy(program_output) \
  evoasm_program_io_destroy((evoasm_program_io *)program_output)
