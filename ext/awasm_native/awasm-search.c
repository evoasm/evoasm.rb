#define _DEFAULT_SOURCE

#include "awasm-search.h"
#include "awasm-error.h"
#include <stdalign.h>

#if 0
#ifdef __STDC_NO_THREADS__
#include "tinycthread.h"
#else
#include <threads.h>
#endif
#endif

AWASM_DECL_LOG_TAG("search")

#define _AWASM_PROGRAM_SIZE(search) \
  (sizeof(awasm_program_params) + search->params.max_program_size * sizeof(awasm_program_param))

#define _AWASM_SEARCH_PROGRAM_PARAMS2(search, programs, program_index) \
  ((awasm_program_params *)((unsigned char *)(programs) + (program_index) * _AWASM_PROGRAM_SIZE(search)))

#define _AWASM_SEARCH_PROGRAM_PARAMS(search, program_index) \
  _AWASM_SEARCH_PROGRAM_PARAMS2(search, search->pop.programs, program_index)

#if (defined(__unix__) || defined(__unix) ||\
    (defined(__APPLE__) && defined(__MACH__)))

#define AWASM_SEARCH_PROLOG_EPILOG_SIZE UINT32_C(1024)

#include <setjmp.h>
#include <stdio.h>
#include <signal.h>
#include <stdatomic.h>

#define _AWASM_SIGNAL_CONTEXT_TRY(signal_ctx) (sigsetjmp((signal_ctx)->env, 1) == 0)
#define _AWASM_SEARCH_EXCEPTION_SET_P(exc) (_awasm_signal_ctx->exception_mask & (1 << exc))

struct awasm_signal_context {
  uint32_t exception_mask;
  sigjmp_buf env;
  struct sigaction prev_action;
  awasm_arch_id arch_id;
};


_Thread_local volatile struct awasm_signal_context *_awasm_signal_ctx;

static void
_awasm_signal_handler(int sig, siginfo_t *siginfo, void *ctx) {
  bool jmp = false;

  atomic_signal_fence(memory_order_acquire);

  switch(_awasm_signal_ctx->arch_id) {
    case AWASM_ARCH_X64: {
      switch(sig) {
        case SIGFPE: {
          bool catch_div_by_zero = siginfo->si_code == FPE_INTDIV &&
            _AWASM_SEARCH_EXCEPTION_SET_P(AWASM_X64_EXCEPTION_DE);
          jmp = catch_div_by_zero;
          break;
        }
        default:
          break;
      }
      break;
    }
    default: awasm_assert_not_reached();
  }

  if(jmp) {
    siglongjmp(*((jmp_buf *)&_awasm_signal_ctx->env), 1);
  } else {
    raise(sig);
  }
}

static void
awasm_signal_context_install(struct awasm_signal_context *signal_ctx, awasm_arch *arch) {
  struct sigaction action = {0};

  signal_ctx->arch_id = arch->cls->id;

  action.sa_sigaction = _awasm_signal_handler;
  sigemptyset(&action.sa_mask);
  action.sa_flags = SA_SIGINFO;

  if(sigaction(SIGFPE, &action, &signal_ctx->prev_action) < 0) {
    perror("sigaction");
    exit(1);
  }

  _awasm_signal_ctx = signal_ctx;
  atomic_signal_fence(memory_order_release);
}

static void
awasm_signal_context_uninstall(struct awasm_signal_context *signal_ctx) {
  if(sigaction(SIGFPE, &signal_ctx->prev_action, NULL) < 0) {
    perror("sigaction");
    exit(1);
  }
}

static void
awasm_signal_context_set_exception_mask(struct awasm_signal_context *signal_ctx, uint32_t mask) {
  signal_ctx->exception_mask = mask;
}

#else
#error
#endif

static inline double
awasm_example_val_to_dbl(awasm_example_val example_val, awasm_example_type example_type) {
  switch(example_type) {
    case AWASM_EXAMPLE_TYPE_F64:
      return example_val.f64;
    case AWASM_EXAMPLE_TYPE_I64:
      return (double) example_val.i64;
    default:
      awasm_fatal("unsupported example type %d", example_type);
      awasm_assert_not_reached();
  }
}

#define AWASM_PROGRAM_OUTPUT_VALS_SIZE(io) \
      ((size_t)AWASM_PROGRAM_IO_N(io) *\
       (size_t)AWASM_PROGRAM_MAX_OUTPUT_REGS *\
       sizeof(awasm_example_val))

static bool
_awasm_population_destroy(awasm_population *pop, bool free_buf, bool free_body_buf) {
  bool retval = true;

  awasm_prng64_destroy(&pop->prng64);
  awasm_prng32_destroy(&pop->prng32);
  awasm_free(pop->programs);
  awasm_free(pop->fitnesses);
  awasm_free(pop->output_vals);
  awasm_free(pop->matching);

  if(free_buf) AWASM_TRY(buf_free_failed, awasm_buf_destroy, &pop->buf);

cleanup:
  if(free_body_buf) AWASM_TRY(body_buf_failed, awasm_buf_destroy, &pop->body_buf);
  return retval;

buf_free_failed:
  retval = false;
  goto cleanup;

body_buf_failed:
  return false;
}

static awasm_success
awasm_population_init(awasm_population *pop, awasm_search *search) {
  uint32_t pop_size = search->params.pop_size;
  unsigned i;

  size_t body_buf_size = (size_t) (search->params.max_program_size * search->arch->cls->max_inst_len);
  size_t buf_size = AWASM_PROGRAM_INPUT_N(&search->params.program_input) * (body_buf_size + AWASM_SEARCH_PROLOG_EPILOG_SIZE);

  static awasm_population zero_pop = {0};
  *pop = zero_pop;

  pop->programs = awasm_calloc(3 * pop_size, _AWASM_PROGRAM_SIZE(search));
  pop->programs_main = pop->programs;
  pop->programs_swap = pop->programs + 1 * search->params.pop_size * _AWASM_PROGRAM_SIZE(search);
  pop->programs_aux = pop->programs + 2 * search->params.pop_size * _AWASM_PROGRAM_SIZE(search);

  pop->output_vals = awasm_malloc(AWASM_PROGRAM_OUTPUT_VALS_SIZE(&search->params.program_input));
  pop->matching = awasm_malloc(search->params.program_output.arity * sizeof(uint_fast8_t));

  pop->fitnesses = (awasm_fitness *) awasm_calloc(pop_size, sizeof(awasm_fitness));
  for(i = 0; i < AWASM_SEARCH_ELITE_SIZE; i++) {
    pop->elite[i] = UINT32_MAX;
  }
  pop->elite_pos = 0;
  pop->best_fitness = INFINITY;

  awasm_prng64_init(&pop->prng64, &search->params.seed64);
  awasm_prng32_init(&pop->prng32, &search->params.seed32);

  AWASM_TRY(buf_alloc_failed, awasm_buf_init, &pop->buf, AWASM_BUF_TYPE_MMAP, buf_size);
  AWASM_TRY(body_buf_alloc_failed, awasm_buf_init, &pop->body_buf, AWASM_BUF_TYPE_MALLOC, body_buf_size);

  AWASM_TRY(prot_failed, awasm_buf_protect, &pop->buf,
      AWASM_BUF_PROT_R | AWASM_BUF_PROT_W | AWASM_BUF_PROT_X);

  return true;

buf_alloc_failed:
  _awasm_population_destroy(pop, false, false);
  return false;

body_buf_alloc_failed:
  _awasm_population_destroy(pop, true, false);
  return false;

prot_failed:
  _awasm_population_destroy(pop, true, true);
  return false;
}

static awasm_success
awasm_population_destroy(awasm_population *pop) {
  return _awasm_population_destroy(pop, true, true);
}

#define AWASM_SEARCH_X64_REG_TMP AWASM_X64_REG_14

static awasm_success
awasm_program_x64_emit_output_save(awasm_program *program,
                                   unsigned example_index) {
  awasm_arch *arch = program->arch;
  awasm_x64 *x64 = (awasm_x64 *) arch;
  awasm_x64_params params = {0};
  unsigned i;

  for(i = 0; i < program->n_output_regs; i++) {
    awasm_example_val *val_addr = &program->output_vals[(program->n_output_regs * example_index) + i];
    enum awasm_x64_reg_type reg_type = awasm_x64_reg_type(program->output_regs[i]);

    awasm_arch_param_val addr_imm = (awasm_arch_param_val)(uintptr_t) val_addr;

    AWASM_X64_SET(AWASM_X64_PARAM_REG0, AWASM_SEARCH_X64_REG_TMP);
    AWASM_X64_SET(AWASM_X64_PARAM_IMM0, addr_imm);
    AWASM_X64_ENC(mov_r64_imm64);
    awasm_arch_save(arch, program->buf);

    switch(reg_type) {
      case AWASM_X64_REG_TYPE_GP: {
        AWASM_X64_SET(AWASM_X64_PARAM_REG1, (awasm_x64_reg_id) program->output_regs[i]);
        AWASM_X64_SET(AWASM_X64_PARAM_REG_BASE, AWASM_SEARCH_X64_REG_TMP);
        AWASM_X64_ENC(mov_rm64_r64);
        awasm_arch_save(arch, program->buf);
        break;
      }
      case AWASM_X64_REG_TYPE_XMM: {
        AWASM_X64_SET(AWASM_X64_PARAM_REG1, (awasm_x64_reg_id) program->output_regs[i]);
        AWASM_X64_SET(AWASM_X64_PARAM_REG_BASE, AWASM_SEARCH_X64_REG_TMP);
        AWASM_X64_ENC(movsd_xmm2m64_xmm1);
        awasm_arch_save(arch, program->buf);
        break;
      }
      default: {
        awasm_assert_not_reached();
      }

    }
  }

  return true;

enc_failed:
  return false;
}

static void
awasm_search_seed_program_param(awasm_search *search, awasm_program_param *program_param) {
  unsigned i;
  int64_t inst_idx = awasm_prng64_rand_between(&search->pop.prng64, 0, search->params.insts_len - 1);
  awasm_inst *inst = search->params.insts[inst_idx];

  program_param->inst = inst;

  /* set parameters */
  for(i = 0; i < search->params.params_len; i++) {
    awasm_domain *domain = &search->domains[inst_idx * search->params.params_len + i];
    if(domain->type < AWASM_N_DOMAIN_TYPES) {
      awasm_arch_param_id param_id = search->params.params[i];
      awasm_arch_param_val param_val;

      param_val = (awasm_arch_param_val) awasm_domain_rand(domain, &search->pop.prng64);
      awasm_arch_params_set(
          program_param->param_vals,
          (awasm_bitmap *) &program_param->set_params,
          param_id,
          param_val
      );
    }
  }
}

static void
awasm_search_seed(awasm_search *search, unsigned char *programs) {
  unsigned i, j;

  for(i = 0; i < search->params.pop_size; i++) {
    awasm_program_params *program_params = _AWASM_SEARCH_PROGRAM_PARAMS2(search, programs, i);

    awasm_program_size program_size = (awasm_program_size) awasm_prng64_rand_between(&search->pop.prng64,
        search->params.min_program_size, search->params.max_program_size);

    program_params->size = program_size;
    for(j = 0; j < program_size; j++) {
      awasm_search_seed_program_param(search, &program_params->params[j]);
    }
  }
}


static awasm_success
awasm_program_x64_emit_rflags_reset(awasm_program *program) {
  awasm_x64 *x64 = (awasm_x64 *) program->arch;
  awasm_x64_params params = {0};

  awasm_debug("emitting RFLAGS reset");
  AWASM_X64_ENC(pushfq);
  awasm_arch_save(program->arch, program->buf);
  AWASM_X64_SET(AWASM_X64_PARAM_REG_BASE, AWASM_X64_REG_SP);
  AWASM_X64_SET(AWASM_X64_PARAM_IMM, 0);
  AWASM_X64_ENC(mov_rm64_imm32);
  awasm_arch_save(program->arch, program->buf);
  AWASM_X64_ENC(popfq);
  awasm_arch_save(program->arch, program->buf);

  return true;
enc_failed:
  return false;
}

static awasm_success
awasm_search_x64_emit_mxcsr_reset(awasm_search *search, awasm_buf *buf) {
  awasm_arch *arch = search->arch;
  static uint32_t default_mxcsr_val = 0x1f80;
  awasm_x64 *x64 = (awasm_x64 *) arch;
  awasm_x64_params params = {0};
  awasm_arch_param_val addr_imm = (awasm_arch_param_val)(uintptr_t) &default_mxcsr_val;

  awasm_x64_reg_id reg_tmp0 = AWASM_X64_REG_14;

  AWASM_X64_SET(AWASM_X64_PARAM_REG0, reg_tmp0);
  AWASM_X64_SET(AWASM_X64_PARAM_IMM0, addr_imm);
  AWASM_X64_ENC(mov_r32_imm32);
  awasm_arch_save(arch, buf);

  AWASM_X64_SET(AWASM_X64_PARAM_REG_BASE, reg_tmp0);
  AWASM_X64_ENC(ldmxcsr_m32);
  awasm_arch_save(arch, buf);

  return true;
enc_failed:
  return false;
}

static void
awasm_program_x64_setup(awasm_program *program) {
  unsigned i, j;
  awasm_program_params *program_params = program->params;

  /*FIXME: hardcoded 4 (max written operands)*/
  uint_fast8_t output_sizes[AWASM_PROGRAM_MAX_OUTPUT_REGS] = {0};

  program->n_input_regs = 0;
  program->n_output_regs = 0;

  for(i = 0; i < program_params->size; i++) {
    awasm_inst *inst = program_params->params[i].inst;
    awasm_x64_inst *x64_inst =  (awasm_x64_inst *) inst;
    awasm_arch_param_val *param_vals = program_params->params[i].param_vals;
    unsigned output_sizes_len = program->n_output_regs;

    for(j = 0; j < x64_inst->n_operands; j++) {
      awasm_x64_operand *op = &x64_inst->operands[j];

      if(op->type == AWASM_X64_OPERAND_TYPE_REG ||
         op->type == AWASM_X64_OPERAND_TYPE_RM) {
        awasm_x64_reg_id reg_id;

        if(op->reg_type == AWASM_X64_REG_TYPE_RFLAGS) {
          if(op->acc_r) {
            program->reset_rflags = true;
          }
        }
        else {
          if(op->param_idx < inst->params_len) {
            reg_id = (awasm_x64_reg_id) param_vals[inst->params[op->param_idx].id];
          } else if(op->reg_id < AWASM_X64_N_REGS) {
            reg_id = op->reg_id;
          } else {
            awasm_assert_not_reached();
          }

          /*
           * Conditional writes (acc_c) might or might not do the write.
           */

          if(op->acc_r || op->acc_c) {
            unsigned k;
            bool dirty_read = true;

            for(k = 0; k < output_sizes_len; k++) {
              /*
               * NOTE: for 8bit writes we do not know
               * if they target the upper or lower 8bit segment
               * thus we always initialize.
               */

              if(program->output_regs[k] == reg_id &&
                 (op->size < output_sizes[k] ||
                   (op->size == output_sizes[k] &&
                    output_sizes[k] != AWASM_X64_OPERAND_SIZE_8))) {
                dirty_read = false;
                break;
              }
            }
            if(dirty_read) {
              program->input_regs[program->n_input_regs] = (awasm_reg_id) reg_id;
              program->n_input_regs++;
            }
          }

          if(op->acc_w) {
            program->output_regs[program->n_output_regs] = (awasm_reg_id) reg_id;
            output_sizes[program->n_output_regs] = (uint_fast8_t)
              AWASM_MAX(output_sizes[program->n_output_regs], op->acc_c ? AWASM_X64_OPERAND_SIZE_UNKNOWN : op->size);

            program->n_output_regs++;
          }
        }
      }
    }
  }

  assert(program->n_output_regs <= AWASM_PROGRAM_MAX_OUTPUT_REGS);
  assert(program->n_input_regs <= AWASM_PROGRAM_MAX_INPUT_REGS);
}

static awasm_success
awasm_program_x64_emit_program_prolog(awasm_program *program,
                                      awasm_example_val *input_vals,
                                      awasm_example_type *types,
                                      unsigned in_arity) {


  awasm_x64 *x64 = (awasm_x64 *) program->arch;
  unsigned i;
  awasm_example_val *loaded_example = NULL;

  for(i = 0; i < program->n_input_regs; i++) {
    awasm_example_val *example = &input_vals[i % in_arity];
    //awasm_example_type type = types[i];
    awasm_x64_reg_id reg_id = (awasm_x64_reg_id) program->input_regs[i];
    awasm_x64_params params = {0};
    enum awasm_x64_reg_type reg_type = awasm_x64_reg_type(reg_id);

    awasm_debug("emitting input register initialization of register %d to value %" PRId64, reg_id, example->i64);

    switch(reg_type) {
      case AWASM_X64_REG_TYPE_GP: {
        AWASM_X64_SET(AWASM_X64_PARAM_REG0, reg_id);
        /*FIXME: hard-coded example type */
        AWASM_X64_SET(AWASM_X64_PARAM_IMM0, (awasm_arch_param_val) example->i64);
        AWASM_X64_ENC(mov_r64_imm64);
        awasm_arch_save(program->arch, program->buf);
        break;
      }
      case AWASM_X64_REG_TYPE_XMM: {
        if(loaded_example != example) {
          AWASM_X64_SET(AWASM_X64_PARAM_REG0, AWASM_SEARCH_X64_REG_TMP);
          AWASM_X64_SET(AWASM_X64_PARAM_IMM0, (awasm_arch_param_val)(uintptr_t) &example->f64);
          AWASM_X64_ENC(mov_r64_imm64);
          loaded_example = example;
        }

        /*FIXME: hard-coded example type */
        AWASM_X64_SET(AWASM_X64_PARAM_REG0, reg_id);
        AWASM_X64_SET(AWASM_X64_PARAM_REG_BASE, AWASM_SEARCH_X64_REG_TMP);
        AWASM_X64_ENC(movsd_xmm1_xmm2m64);
        awasm_arch_save(program->arch, program->buf);
        break;
      }
      default:
        awasm_fatal("non-gpr register type (unimplemented)");
        awasm_assert_not_reached();
    }
  }

  if(program->reset_rflags) {
    AWASM_TRY(error, awasm_program_x64_emit_rflags_reset, program);
  }
  return true;

error:
enc_failed:
  return false;
}

static awasm_success
awasm_program_x64_emit_program_body(awasm_program *program) {
  unsigned i;
  uint32_t exception_mask = 0;
  awasm_program_params *program_params = program->params;
  awasm_buf *buf = program->body_buf;
  awasm_arch *arch = program->arch;

  for(i = 0; i < program_params->size; i++) {
    awasm_inst *inst = program_params->params[i].inst;
    awasm_x64_inst *x64_inst = (awasm_x64_inst *) inst;
    exception_mask = exception_mask | x64_inst->exceptions;
    AWASM_TRY(error, awasm_inst_encode,
                      inst,
                      arch,
                      program_params->params[i].param_vals,
                      (awasm_bitmap *) &program_params->params[i].set_params);

    awasm_arch_save(arch, buf);
  }

  awasm_signal_context_set_exception_mask((struct awasm_signal_context *) program->_signal_ctx, exception_mask);

  return true;
error:
  return false;
}

static awasm_success
awasm_program_x64_emit(awasm_program *program,
                       awasm_program_input *input) {
  unsigned i;
  unsigned n_examples = AWASM_PROGRAM_INPUT_N(input);

  awasm_buf_reset(program->body_buf);
  awasm_buf_reset(program->buf);

  AWASM_TRY(error, awasm_program_x64_emit_program_body, program);

  awasm_program_x64_setup(program);

  AWASM_TRY(error, awasm_x64_func_prolog, (awasm_x64 *) program->arch, program->buf, AWASM_X64_ABI_SYSV);

  for(i = 0; i < n_examples; i++) {
    awasm_example_val *input_vals = input->vals + i * input->arity;
    awasm_debug("emitting program %d for example %d", program->index, i);
    AWASM_TRY(error, awasm_program_x64_emit_program_prolog, program, input_vals, input->types, input->arity);
    {
      size_t r = awasm_buf_append(program->buf, program->body_buf);
      assert(r == 0);
    }
    AWASM_TRY(error, awasm_program_x64_emit_output_save, program, i);
  }

  AWASM_TRY(error, awasm_x64_func_epilog, (awasm_x64 *) program->arch, program->buf, AWASM_X64_ABI_SYSV);
  return true;

error:
  return false;
}

static bool
awasm_program_emit(awasm_program *program,
                   awasm_program_input *input) {
  awasm_arch *arch = program->arch;

  switch(arch->cls->id) {
    case AWASM_ARCH_X64: {
      return awasm_program_x64_emit(program, input);
      break;
    }
    default:
      awasm_assert_not_reached();
  }
}

typedef enum {
  AWASM_METRIC_ABSDIFF,
  AWASM_N_METRICS
} awasm_metric;

static inline void
awasm_program_update_dist_mat(awasm_program *program,
                              awasm_program_output *output,
                              unsigned height,
                              unsigned example_index,
                              double *matrix,
                              awasm_metric metric) {
  unsigned i, j;
  unsigned width = program->n_output_regs;
  awasm_example_val *example_vals = output->vals + example_index * output->arity;

  for(i = 0; i < height; i++) {
    awasm_example_val example_val = example_vals[i];
    awasm_example_type example_type = output->types[i];
    double example_val_dbl = awasm_example_val_to_dbl(example_val, example_type);

    for(j = 0; j < width; j++) {
      awasm_example_val output_val = program->output_vals[example_index * width + j];
      //uint8_t output_size = program->output_sizes[j];
      //switch(output_size) {
      //  
      //}
      // FIXME: output is essentially just a bitstring and could be anything
      // an integer (both, signed or unsigned) a float or double.
      // Moreover, a portion of the output value could
      // hold the correct answer (e.g. lower 8 or 16 bits etc.).
      // For now we use the example output type and assume signedness.
      // This needs to be fixed.
      double output_val_dbl = awasm_example_val_to_dbl(output_val, example_type);

      switch(metric) {
        default:
        case AWASM_METRIC_ABSDIFF: {
          double dist = fabs(output_val_dbl - example_val_dbl);
          matrix[i * width + j] += dist;
          break;
        }
      }
    }
  }
}

static void
awasm_program_log_program_output(awasm_program *program,
                                  awasm_program_output *output,
                                  uint_fast8_t *matching,
                                  awasm_log_level log_level) {

  unsigned n_examples = AWASM_PROGRAM_OUTPUT_N(output);
  unsigned height = output->arity;
  unsigned width = program->n_output_regs;
  unsigned i, j, k;

  awasm_log(log_level, AWASM_LOG_TAG, "OUTPUT MATRICES:\n");
  for(i = 0; i < n_examples; i++) {
    for(j = 0; j < height; j++) {
      for(k = 0; k < width; k++) {
        bool matched = matching[j] == k;
        awasm_example_val val = program->output_vals[i * width + k];
        if(matched) {
          awasm_log(log_level, AWASM_LOG_TAG, " \x1b[1m ");
        }
        awasm_log(log_level, AWASM_LOG_TAG, " %ld (%f)\t ", val.i64, val.f64);
        if(matched) {
          awasm_log(log_level, AWASM_LOG_TAG, " \x1b[0m ");
        }
      }
      awasm_log(log_level, AWASM_LOG_TAG, " \n ");
    }
    awasm_log(log_level, AWASM_LOG_TAG, " \n\n ");
  }
}

static void
awasm_program_log_dist_matrix(awasm_program *program,
                              unsigned height,
                              double *matrix,
                              uint_fast8_t *matching,
                              awasm_log_level log_level) {

  unsigned width = program->n_output_regs;
  unsigned i, j;

  awasm_log(log_level, AWASM_LOG_TAG, "DIST MATRIX: (%d, %d)\n", height, width);
  for(i = 0; i < height; i++) {
    for(j = 0; j < width; j++) {
      if(matching[i] == j) {
        awasm_log(log_level, AWASM_LOG_TAG, " \x1b[1m ");
      }
      awasm_log(log_level, AWASM_LOG_TAG, " %.2g\t ", matrix[i * width + j]);
      if(matching[i] == j) {
        awasm_log(log_level, AWASM_LOG_TAG, " \x1b[0m ");
      }
    }
    awasm_log(log_level, AWASM_LOG_TAG, " \n ");
  }
  awasm_log(log_level, AWASM_LOG_TAG, " \n\n ");
}


static inline bool
awasm_program_find_min_dist(awasm_program *program,
                            unsigned width,
                            double *matrix,
                            uint_fast8_t *matching) {

  uint_fast8_t best_index = UINT_FAST8_MAX;
  double best_dist = INFINITY;
  uint_fast8_t i;

  for(i = 0; i < width; i++) {
    double v = matrix[i];
    if(v < best_dist) {
      best_dist = v;
      best_index = i;
    }
  }

  if(AWASM_LIKELY(best_index != UINT_FAST8_MAX)) {
    *matching = best_index;
    return true;
  } else {
    /*awasm_program_log_dist_matrix(program,
                                  1,
                                  matrix,
                                  matching,
                                  AWASM_LOG_LEVEL_WARN);
    awasm_assert_not_reached();*/
    /*
     * Might happen if all elements are inf or nan
     */
    return false;
  }
}

static inline void
awasm_program_calc_stable_matching(awasm_program *program,
                                   unsigned height,
                                   double *matrix,
                                   uint_fast8_t *matching) {

  uint_fast8_t width =  (uint_fast8_t) program->n_output_regs;
  uint_fast8_t *inv_matching = alloca(width * sizeof(uint_fast8_t));
  uint_fast8_t i;

  // calculates a stable matching
  for(i = 0; i < height; i++) {
    matching[i] = UINT_FAST8_MAX;
  }

  for(i = 0; i < width; i++) {
    inv_matching[i] = UINT_FAST8_MAX;
  }

  while(true) {
    uint_fast8_t unmatched_index = UINT_FAST8_MAX;
    uint_fast8_t best_index = UINT_FAST8_MAX;
    double best_dist = INFINITY;

    for(i = 0; i < height; i++) {
      if(matching[i] == UINT_FAST8_MAX) {
        unmatched_index = i;
        break;
      }
    }

    if(unmatched_index == UINT_FAST8_MAX) {
      break;
    }

    for(i = 0; i < width; i++) {
      double v = matrix[unmatched_index * width + i];
      if(v < best_dist) {
        best_dist = v;
        best_index = i;
      }
    }

    if(AWASM_LIKELY(best_index != UINT_FAST8_MAX)) {
      if(inv_matching[best_index] == UINT_FAST8_MAX) {
        inv_matching[best_index] = unmatched_index;
        matching[unmatched_index] = best_index;
      }
      else {
        if(matrix[inv_matching[best_index] * width + best_index] > best_dist) {
          matching[inv_matching[best_index]] = UINT_FAST8_MAX;
          inv_matching[best_index] = unmatched_index;
          matching[unmatched_index] = best_index;
        } else {
          //matrix[unmatched_index * width + i] = copysign(best_dist, -1.0);
          matrix[unmatched_index * width + i] = INFINITY;
        }
      }
    }
    else {
      awasm_program_log_dist_matrix(program,
                                    height,
                                    matrix,
                                    matching,
                                    AWASM_LOG_LEVEL_DEBUG);
      awasm_assert_not_reached();
    }
  }
}


static inline awasm_fitness
awasm_program_calc_fitness(awasm_program *program,
                           unsigned height,
                           double *matrix,
                           uint_fast8_t *matching) {
  unsigned i;
  unsigned width = program->n_output_regs;
  double scale = 1.0 / width;
  awasm_fitness fitness = 0.0;

  for(i = 0; i < height; i++) {
    fitness += scale * matrix[i * width + matching[i]];
  }

  return fitness;
}

static awasm_fitness
awasm_program_assess(awasm_program *program,
                     awasm_program_output *output,
                     uint_fast8_t *matching) {

  unsigned i;
  unsigned n_examples = AWASM_PROGRAM_OUTPUT_N(output);
  unsigned height = output->arity;
  unsigned width =  program->n_output_regs;
  size_t matrix_len = (size_t)(width * height);
  double *matrix = alloca(matrix_len * sizeof(double));
  awasm_fitness fitness;

  for(i = 0; i < matrix_len; i++) {
    matrix[i] = 0.0;
  }

  if(height == 1) {
    /* COMMON FAST-PATH */
    for(i = 0; i < n_examples; i++) {
      awasm_program_update_dist_mat(program, output, 1, i, matrix, AWASM_METRIC_ABSDIFF);
    }

    if(awasm_program_find_min_dist(program, width, matrix, matching)) {
      fitness = awasm_program_calc_fitness(program, 1, matrix, matching);
    } else {
      fitness = INFINITY;
    }
  }
  else {
    for(i = 0; i < n_examples; i++) {
      awasm_program_update_dist_mat(program, output, height, i, matrix, AWASM_METRIC_ABSDIFF);
    }

    awasm_program_calc_stable_matching(program, height, matrix, matching);
    fitness = awasm_program_calc_fitness(program, height, matrix, matching);
  }

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_DEBUG
  /* < is just to silence warning */
  if(fitness == 0.0) {
    awasm_program_log_program_output(program,
                                      output,
                                      matching,
                                      AWASM_LOG_LEVEL_DEBUG);
  }
#endif

  return fitness;
}

static void
awasm_program_load_output(awasm_program *program,
                          awasm_program_input *input,
                          awasm_program_output *output,
                          uint_fast8_t *matching,
                          awasm_program_output *loaded_output) {

  unsigned i, j;
  unsigned width = program->n_output_regs;
  unsigned height = output->arity;
  unsigned n_examples = AWASM_PROGRAM_INPUT_N(input);

  loaded_output->len = (uint16_t)(AWASM_PROGRAM_INPUT_N(input) * output->arity);
  loaded_output->vals = awasm_malloc((size_t) loaded_output->len * sizeof(awasm_example_val));

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_INFO
  awasm_program_log_program_output(program,
                                    output,
                                    matching,
                                    AWASM_LOG_LEVEL_DEBUG);
#endif

  for(i = 0; i < n_examples; i++) {
    for(j = 0; j < height; j++) {
      loaded_output->vals[i * height + j] = program->output_vals[i * width + matching[j]];
    }
  }

  loaded_output->arity = output->arity;
  memcpy(loaded_output->types, output->types, AWASM_ARY_LEN(output->types));
}

void
awasm_program_io_destroy(awasm_program_io *program_io) {
  awasm_free(program_io->vals);
}

awasm_success
awasm_program_run(awasm_program *program,
                  awasm_program_input *input,
                  awasm_program_output *output) {
  bool retval;
  struct awasm_signal_context signal_ctx = {0};
  unsigned i;

  if(input->arity != program->_input.arity) {
    awasm_set_error(AWASM_ERROR_TYPE_ARGUMENT, AWASM_ERROR_CODE_NONE, NULL,
        "example arity mismatch (%d for %d)", input->arity, program->_input.arity);
    return false;
  }

  for(i = 0; i < input->arity; i++) {
    if(input->types[i] != program->_input.types[i]) {
       awasm_set_error(AWASM_ERROR_TYPE_ARGUMENT, AWASM_ERROR_CODE_NONE, NULL,
           "example type mismatch (%d != %d)", input->types[i], program->_input.types[i]);
      return false;
    }
  }

  program->output_vals = alloca(AWASM_PROGRAM_OUTPUT_VALS_SIZE(input));
  program->_signal_ctx = &signal_ctx;
  awasm_program_emit(program, input);

  // FIXME:
  if(program->n_output_regs == 0) {
    return true;
  }

  awasm_buf_log(program->buf, AWASM_LOG_LEVEL_DEBUG);
  awasm_signal_context_install(&signal_ctx, program->arch);

  if(!awasm_buf_protect(program->buf, AWASM_BUF_PROT_X)) {
    awasm_assert_not_reached();
  }

  if(_AWASM_SIGNAL_CONTEXT_TRY(&signal_ctx)) {
    awasm_buf_exec(program->buf);
    awasm_program_load_output(program,
                              input,
                              &program->_output,
                              program->_matching,
                              output);
    retval = true;
  } else {
    awasm_debug("signaled\n");
    retval = false;
  }

  if(!awasm_buf_protect(program->buf, AWASM_BUF_PROT_R | AWASM_BUF_PROT_W)) {
    awasm_assert_not_reached();
  }

  awasm_signal_context_uninstall(&signal_ctx);

  program->_signal_ctx = NULL;
  program->output_vals = NULL;

  return retval;
}

static awasm_fitness
awasm_search_eval_program(awasm_search *search,
                          awasm_program *program) {

  awasm_fitness fitness;
  awasm_program_emit(program, &search->params.program_input);

  if(AWASM_UNLIKELY(program->n_output_regs == 0)) {
    return INFINITY;
  }

  //awasm_buf_log(program->buf, AWASM_LOG_LEVEL_INFO);

  if(_AWASM_SIGNAL_CONTEXT_TRY((struct awasm_signal_context *)program->_signal_ctx)) {
    awasm_buf_exec(program->buf);
    fitness = awasm_program_assess(program, &search->params.program_output, search->pop.matching);
  } else {
    awasm_debug("program %d signaled", program->index);
    fitness = INFINITY;
  }
  return fitness;
}

static bool
awasm_search_eval_population(awasm_search *search, unsigned char *programs,
                             awasm_fitness min_fitness, awasm_search_result_func result_func,
                             void *user_data) {
  unsigned i;
  struct awasm_signal_context signal_ctx = {0};
  awasm_population *pop = &search->pop;
  bool retval;
  unsigned n_examples = AWASM_PROGRAM_INPUT_N(&search->params.program_input);

  awasm_signal_context_install(&signal_ctx, search->arch);

  for(i = 0; i < search->params.pop_size; i++) {
    awasm_fitness fitness;
    awasm_program_params *program_params = _AWASM_SEARCH_PROGRAM_PARAMS2(search, programs, i);
    /* encode solution */
    awasm_program program = {
      .params = program_params,
      .index = i,
      .buf = &search->pop.buf,
      .body_buf = &search->pop.body_buf,
      .arch = search->arch,
      ._signal_ctx = &signal_ctx
    };

    program.output_vals = pop->output_vals;

    fitness = awasm_search_eval_program(search, &program);
    pop->fitnesses[i] = fitness;

    awasm_debug("program %d has fitness %lf", i, fitness);

    if(fitness <= pop->best_fitness) {
      pop->elite[pop->elite_pos++ % AWASM_SEARCH_ELITE_SIZE] = i;
      pop->best_fitness = fitness;
      awasm_debug("program %d has best fitness %lf", i, fitness);
    }

    if(AWASM_UNLIKELY(fitness / n_examples <= min_fitness)) {
      program._output = search->params.program_output;
      program._input = search->params.program_output;
      program._matching = search->pop.matching;

      if(!result_func(&program, fitness, user_data)) {
        retval = false;
        goto done;
      }
    }
  }

  retval = true;
done:
  awasm_signal_context_uninstall(&signal_ctx);
  return retval;
}

static void
awasm_search_select_parents(awasm_search *search, uint32_t *parents) {
  uint32_t n = 0;
  unsigned i, j, k;

  /* find out degree elite array is really filled */
  for(i = 0; i < AWASM_SEARCH_ELITE_SIZE; i++) {
    if(search->pop.elite[i] == UINT32_MAX) {
      break;
    }
  }

  /* fill possible free slots */
  for(j = i, k = 0; j < AWASM_SEARCH_ELITE_SIZE; j++) {
    search->pop.elite[j] = search->pop.elite[k++ % i];
  }

  j = 0;
  while(true) {
    for(i = 0; i < search->params.pop_size; i++) {
      uint32_t r = awasm_prng32_rand(&search->pop.prng32);
      if(n >= search->params.pop_size) goto done;
      if(r < UINT32_MAX * ((search->pop.best_fitness + 1.0) / (search->pop.fitnesses[i] + 1.0))) {
        parents[n++] = i;
        //awasm_info("selecting fitness %f", search->pop.fitnesses[i]);
      } else if(r < UINT32_MAX / 32) {
        parents[n++] = search->pop.elite[j++ % AWASM_SEARCH_ELITE_SIZE];
        //awasm_info("selecting elite fitness %f", search->pop.fitnesses[parents[n - 1]]);
      } else {
        //awasm_info("discarding fitness %f", search->pop.fitnesses[i]);
      }
    }
  }
done:;
}

static void
awasm_search_mutate_child(awasm_search *search, awasm_program_params *child) {
  uint32_t r = awasm_prng32_rand(&search->pop.prng32);
  awasm_debug("mutating child: %u < %u", r, search->params.mutation_rate);
  if(r < search->params.mutation_rate) {

    r = awasm_prng32_rand(&search->pop.prng32);
    if(child->size > search->params.min_program_size && r < UINT32_MAX / 16) {
      uint32_t index = r % child->size;

      if(index < (uint32_t) (child->size - 1)) {
        memmove(child->params + index, child->params + index + 1, (child->size - index - 1) * sizeof(awasm_program_param));
      }
      child->size--;
    }


    r = awasm_prng32_rand(&search->pop.prng32);
    {
      awasm_program_param *program_param = child->params + (r % child->size);
      awasm_search_seed_program_param(search, program_param);
    }
  }
}

static void
awasm_search_generate_child(awasm_search *search, awasm_program_params *parent_a, awasm_program_params *parent_b,
                            awasm_program_params *child) {

    /* NOTE: parent_a must be the longer parent, i.e. parent_size_a >= parent_size_b */

    awasm_program_size child_size;
    unsigned crossover_point, crossover_len, i;

    assert(parent_a->size >= parent_b->size);

    child_size = (awasm_program_size)
      awasm_prng32_rand_between(&search->pop.prng32,
        parent_b->size, parent_a->size);

    assert(child_size > 0);
    assert(child_size >= parent_b->size);

    /* offset for shorter parent */
    crossover_point = (unsigned) awasm_prng32_rand_between(&search->pop.prng32,
        0, child_size - parent_b->size);
    crossover_len = (unsigned) awasm_prng32_rand_between(&search->pop.prng32,
        0, parent_b->size);


    for(i = 0; i < child_size; i++) {
      unsigned index;
      awasm_program_params *parent;

      if(i < crossover_point || i >= crossover_point + crossover_len) {
        parent = parent_a;
        index = i;
      } else {
        parent = parent_b;
        index = i - crossover_point;
      }
      child->params[i] = parent->params[index];
    }
    child->size = child_size;

    awasm_search_mutate_child(search, child);
}

static void
awasm_search_crossover(awasm_search *search, awasm_program_params *parent_a, awasm_program_params *parent_b,
                       awasm_program_params *child_a, awasm_program_params *child_b) {

  if(parent_a->size < parent_b->size) {
    awasm_program_params *t = parent_a;
    parent_a = parent_b;
    parent_b = t;
  }

  //memcpy(_AWASM_SEARCH_PROGRAM_PARAMS2(search, programs, index), parent_a, _AWASM_PROGRAM_SIZE(search));
  //memcpy(_AWASM_SEARCH_PROGRAM_PARAMS2(search, programs, index + 1), parent_a, _AWASM_PROGRAM_SIZE(search));

  awasm_search_generate_child(search, parent_a, parent_b, child_a);
  if(child_b != NULL) {
    awasm_search_generate_child(search, parent_a, parent_b, child_b);
  }
}

static void
awasm_search_combine_parents(awasm_search *search, unsigned char *programs, uint32_t *parents) {
  unsigned i;

  for(i = 0; i < search->params.pop_size; i += 2) {
    awasm_program_params *parent_a = _AWASM_SEARCH_PROGRAM_PARAMS2(search, programs, parents[i]);
    awasm_program_params *parent_b = _AWASM_SEARCH_PROGRAM_PARAMS2(search, programs, parents[i + 1]);
    awasm_program_params *child_a = _AWASM_SEARCH_PROGRAM_PARAMS2(search, search->pop.programs_swap, i);
    awasm_program_params *child_b = _AWASM_SEARCH_PROGRAM_PARAMS2(search, search->pop.programs_swap, i + 1);
    awasm_search_crossover(search, parent_a, parent_b, child_a, child_b);
  }
}

static void
awasm_population_swap(awasm_population *pop, unsigned char **programs) {
  unsigned char *programs_tmp;

  programs_tmp = pop->programs_swap;
  pop->programs_swap = *programs;
  *programs = programs_tmp;
}

static awasm_fitness
awasm_search_population_fitness(awasm_search *search, unsigned *n_inf) {
  unsigned i;
  double scale = 1.0 / search->params.pop_size;
  double pop_fitness = 0.0;
  *n_inf = 0;
  for(i = 0; i < search->params.pop_size; i++) {
    double fitness = search->pop.fitnesses[i];
    if(fitness != INFINITY) {
      pop_fitness += scale * fitness;
    }
    else {
      (*n_inf)++;
    }
  }

  return pop_fitness;
}

static void
awasm_search_new_generation(awasm_search *search, unsigned char **programs) {
  uint32_t *parents = alloca(search->params.pop_size * sizeof(uint32_t));
  awasm_search_select_parents(search, parents);

#if 0
  {
    double scale = 1.0 / search->params.pop_size;
    double pop_fitness = 0.0;
    unsigned n_inf = 0;
    for(i = 0; i < search->params.pop_size; i++) {
      double fitness = search->pop.fitnesses[parents[i]];
      if(fitness != INFINITY) {
        pop_fitness += scale * fitness;
      }
      else {
        n_inf++;
      }
    }

    awasm_info("population selected fitness: %g/%u", pop_fitness, n_inf);
  }

  unsigned i;
  for(i = 0; i < search->params.pop_size; i++) {
    awasm_program_params *program_params = _AWASM_SEARCH_PROGRAM_PARAMS(search, parents[i]);
    assert(program_params->size > 0);
  }
#endif

  awasm_search_combine_parents(search, *programs, parents);
  awasm_population_swap(&search->pop, programs);
}

#define AWASM_SEARCH_CONVERGENCE_THRESHOLD 0.03

static bool
awasm_search_start_(awasm_search *search, unsigned char **programs,
                    awasm_fitness min_fitness, awasm_search_result_func result_func,
                    void *user_data) {
  unsigned gen;
  awasm_fitness last_fitness = 0.0;
  unsigned ups = 0;

  for(gen = 0; gen < search->params.program_input.len; gen++) {
    fprintf(stderr, "VALUE: %f\n", *(double *) &search->params.program_input.vals[gen]);
  }


  for(gen = 0;;gen++) {
    if(!awasm_search_eval_population(search, *programs, min_fitness, result_func, user_data)) {
      return true;
    }

    if(gen % 256 == 0) {
      unsigned n_inf;
      awasm_fitness fitness = awasm_search_population_fitness(search, &n_inf);
      awasm_info("population fitness: %g/%u\n\n", fitness, n_inf);

      if(gen > 0) {
        if(last_fitness <= fitness) {
          ups++;
        }
      }

      last_fitness = fitness;

      if(ups >= 3) {
        awasm_info("reached convergence\n");
        return false;
      }
    }

    awasm_search_new_generation(search, programs);
  }
}

static void
awasm_search_merge(awasm_search *search) {
  unsigned i;

  awasm_info("merging\n");

  for(i = 0; i < search->params.pop_size; i++) {
    awasm_program_params *parent_a = _AWASM_SEARCH_PROGRAM_PARAMS2(search, search->pop.programs_main, i);
    awasm_program_params *parent_b = _AWASM_SEARCH_PROGRAM_PARAMS2(search, search->pop.programs_aux, i);

    awasm_program_params *child = _AWASM_SEARCH_PROGRAM_PARAMS2(search, search->pop.programs_swap, i);
    awasm_search_crossover(search, parent_a, parent_b, child, NULL);
  }
  awasm_population_swap(&search->pop, &search->pop.programs_main);
}

void
awasm_search_start(awasm_search *search, awasm_fitness min_fitness, awasm_search_result_func result_func, void *user_data) {

  unsigned kalpa;

  awasm_search_seed(search, search->pop.programs_main);

  for(kalpa = 0;;kalpa++) {
    if(!awasm_search_start_(search, &search->pop.programs_main, min_fitness, result_func, user_data)) {
      awasm_search_seed(search, search->pop.programs_aux);
      awasm_info("starting aux search");
      if(!awasm_search_start_(search, &search->pop.programs_aux, min_fitness, result_func, user_data)) {
        awasm_search_merge(search);
      }
      else {
        goto done;
      }
    }
    else {
      goto done;
    }
  }

done:;
}

awasm_success
awasm_search_init(awasm_search *search, awasm_arch *arch, awasm_search_params *search_params) {
  unsigned i, j, k;
  awasm_domain cloned_domain;
  awasm_arch_params_bitmap active_params = {0};

  search->params = *search_params;
  search->arch = arch;

  AWASM_TRY(fail, awasm_population_init, &search->pop, search);

  for(i = 0; i < search_params->params_len; i++) {
    awasm_bitmap_set((awasm_bitmap *) &active_params, search_params->params[i]);
  }

  search->domains = awasm_calloc((size_t)(search->params.insts_len * search->params.params_len),
      sizeof(awasm_domain));

  for(i = 0; i < search->params.insts_len; i++) {
    awasm_inst *inst = search->params.insts[i];
    for(j = 0; j < search->params.params_len; j++) {
      awasm_domain *inst_domain = &search->domains[i * search->params.params_len + j];
      awasm_arch_param_id param_id =search->params.params[j];
      for(k = 0; k < inst->params_len; k++) {
        awasm_arch_param *param = &inst->params[k];
        if(param->id == param_id) {
          awasm_domain *user_domain = search->params.domains[param_id];
          if(user_domain != NULL) {
            awasm_domain_clone(user_domain, &cloned_domain);
            awasm_domain_intersect(&cloned_domain, param->domain, inst_domain);
          } else {
            awasm_domain_clone(param->domain, inst_domain);
          }
          goto found;
        }
      }
      /* not found */
      inst_domain->type = AWASM_N_DOMAIN_TYPES;
found:;
    }
  }

  assert(search->params.min_program_size > 0);
  assert(search->params.min_program_size <= search->params.max_program_size);

  return true;
fail:
  return false;
}

awasm_success
awasm_search_destroy(awasm_search *search) {
  unsigned i;

  for(i = 0; i < AWASM_ARCH_MAX_PARAMS; i++) {
    awasm_free(search->params.domains[i]);
  }
  awasm_free(search->params.program_input.vals);
  awasm_free(search->params.program_output.vals);
  awasm_free(search->params.params);
  awasm_free(search->domains);
  AWASM_TRY(error, awasm_population_destroy, &search->pop);

  return true;
error:
  return false;
}
