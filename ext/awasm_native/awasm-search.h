#pragma once

#include <stdint.h>
#include <stdlib.h>

#include "awasm.h"
#include "awasm-buf.h"
#include "awasm-x64.h"

typedef double awasm_fitness;
typedef uint8_t awasm_program_size;

typedef enum {
  AWASM_EXAMPLE_TYPE_I64,
  AWASM_EXAMPLE_TYPE_U64,
  AWASM_EXAMPLE_TYPE_F64,
} awasm_example_type;

typedef struct {
  union {
    double f64;
    int64_t i64;
    uint64_t u64;
  };
} awasm_example_val;

#define AWASM_PROGRAM_IO_MAX_ARITY 8

typedef struct {
  uint8_t arity;
  uint16_t len;
  awasm_example_val *vals;
  awasm_example_type types[AWASM_PROGRAM_IO_MAX_ARITY];
  awasm_reg_id regs[AWASM_PROGRAM_IO_MAX_ARITY];
} awasm_program_io;

#define AWASM_PROGRAM_OUTPUT_MAX_ARITY AWASM_PROGRAM_IO_MAX_ARITY
#define AWASM_PROGRAM_INPUT_MAX_ARITY AWASM_PROGRAM_IO_MAX_ARITY
typedef awasm_program_io awasm_program_output;
typedef awasm_program_io awasm_program_input;

#define AWASM_PROGRAM_IO_N(program_io) ((uint16_t)((program_io)->len / (program_io)->arity))
#define AWASM_PROGRAM_INPUT_N(program_input) AWASM_PROGRAM_IO_N((awasm_program_io *)program_input)
#define AWASM_PROGRAM_OUTPUT_N(program_output) AWASM_PROGRAM_IO_N((awasm_program_io *)program_output)

typedef struct {
  awasm_inst *inst;
  awasm_arch_params_bitmap set_params;
  awasm_arch_param_val param_vals[AWASM_ARCH_MAX_PARAMS];
} awasm_program_param;

typedef struct {
  awasm_program_size size;
  awasm_program_param params[];
} awasm_program_params;

#define AWASM_PROGRAM_MAX_OUTPUT_REGS 254
#define AWASM_PROGRAM_MAX_INPUT_REGS 254

typedef struct {
  awasm_program_params *params;
  awasm_reg_id output_regs[AWASM_PROGRAM_MAX_OUTPUT_REGS];
  awasm_reg_id input_regs[AWASM_PROGRAM_MAX_INPUT_REGS];
  uint_fast8_t n_output_regs;
  uint_fast8_t n_input_regs;
  uint8_t in_arity;
  uint8_t out_arity;
  awasm_example_type types[AWASM_PROGRAM_OUTPUT_MAX_ARITY];
  awasm_example_val *output_vals;
  awasm_arch *arch;
  awasm_buf *buf;
  awasm_buf *body_buf;
  uint32_t index;
  bool reset_rflags;
  void *_signal_ctx;

  awasm_program_input _input;
  awasm_program_output _output;
  uint_fast8_t *_matching;
} awasm_program;

#define AWASM_SEARCH_ELITE_SIZE 4

typedef struct {
  awasm_prng64 prng64;
  awasm_prng32 prng32;
  awasm_fitness best_fitness;
  awasm_buf buf;
  awasm_buf body_buf;

  uint32_t elite[AWASM_SEARCH_ELITE_SIZE];
  uint8_t elite_pos;
  uint_fast8_t *matching;
  awasm_example_val *output_vals;
  awasm_fitness *fitnesses;
  unsigned char *programs;
  unsigned char *programs_main;
  unsigned char *programs_swap;
  unsigned char *programs_aux;
} awasm_population;

#define AWASM_EXAMPLES_MAX_ARITY 8
typedef struct {
  awasm_example_type types[AWASM_EXAMPLES_MAX_ARITY];
  uint16_t len;
  awasm_example_val *vals;
  uint8_t in_arity;
  uint8_t out_arity;
} awasm_examples;

typedef struct {
  awasm_inst **insts;
  awasm_program_size min_program_size;
  awasm_program_size max_program_size;
  uint16_t insts_len;
  uint8_t params_len;
  uint32_t pop_size;
  uint32_t mutation_rate;
  awasm_program_input program_input;
  awasm_program_output program_output;
  awasm_arch_param_id *params;
  awasm_prng64_seed seed64;
  awasm_prng32_seed seed32;
  awasm_domain *domains[AWASM_ARCH_MAX_PARAMS];

} awasm_search_params;

typedef struct {
  awasm_arch *arch;
  awasm_population pop;
  awasm_search_params params;
  awasm_domain *domains;
} awasm_search;

bool
awasm_search_init(awasm_search *search,
                  awasm_arch *arch, awasm_search_params *params);

bool
awasm_search_destroy(awasm_search *search);

typedef bool (*awasm_search_result_func)(awasm_program *program,
                                         awasm_fitness fitness, void *user_data);

void
awasm_search_start(awasm_search *search, awasm_fitness min_fitness,
                   awasm_search_result_func func, void *user_data);

bool
awasm_program_run(awasm_program *program,
                  awasm_program_input *input,
                  awasm_program_output *output);

void
awasm_program_io_destroy(awasm_program_io *program_io);

#define awasm_program_output_destroy(program_output) \
  awasm_program_io_destroy((awasm_program_io *)program_output)
