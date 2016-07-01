#define _DEFAULT_SOURCE

#include "evoasm-search.h"
#include "evoasm-error.h"
#include <stdalign.h>

#if 0
#ifdef __STDC_NO_THREADS__
#include "tinycthread.h"
#else
#include <threads.h>
#endif
#endif

EVOASM_DECL_LOG_TAG("search")

#define _EVOASM_KERNEL_SIZE(max_kernel_size) \
   (sizeof(evoasm_kernel_params) + \
    (max_kernel_size) * sizeof(evoasm_kernel_param))

#define _EVOASM_PROGRAM_SIZE(max_program_size, max_kernel_size) \
  (sizeof(evoasm_program_params) + \
   (max_program_size) * _EVOASM_KERNEL_SIZE(max_kernel_size))

#define _EVOASM_SEARCH_PROGRAM_PARAMS(search, programs, program_index) \
  ((evoasm_program_params *)((unsigned char *)(programs) + (program_index) * _EVOASM_PROGRAM_SIZE(search->params.max_program_size, search->params.max_kernel_size)))

#define _EVOASM_PROGRAM_PARAMS_KERNEL_PARAMS(program_params, max_kernel_size, kernel_index) \
  ((evoasm_kernel_params *)((unsigned char *)(program_params) + sizeof(evoasm_program_params) + (kernel_index) * _EVOASM_KERNEL_SIZE(max_kernel_size)))

#define EVOASM_PROGRAM_OUTPUT_VALS_SIZE(io) \
      ((size_t)EVOASM_PROGRAM_IO_N(io) * \
       (size_t)EVOASM_KERNEL_MAX_OUTPUT_REGS * \
       sizeof(evoasm_example_val))

#if (defined(__unix__) || defined(__unix) ||\
    (defined(__APPLE__) && defined(__MACH__)))

#define EVOASM_SEARCH_PROLOG_EPILOG_SIZE UINT32_C(1024)

#include <setjmp.h>
#include <stdio.h>
#include <signal.h>
#include <stdatomic.h>

#define _EVOASM_SIGNAL_CONTEXT_TRY(signal_ctx) (sigsetjmp((signal_ctx)->env, 1) == 0)
#define _EVOASM_SEARCH_EXCEPTION_SET_P(exc) (_evoasm_signal_ctx->exception_mask & (1 << exc))

struct evoasm_signal_context {
  uint32_t exception_mask;
  sigjmp_buf env;
  struct sigaction prev_action;
  evoasm_arch_id arch_id;
};


_Thread_local volatile struct evoasm_signal_context *_evoasm_signal_ctx;

static void
_evoasm_signal_handler(int sig, siginfo_t *siginfo, void *ctx) {
  bool jmp = false;

  atomic_signal_fence(memory_order_acquire);

  switch(_evoasm_signal_ctx->arch_id) {
    case EVOASM_ARCH_X64: {
      switch(sig) {
        case SIGFPE: {
          bool catch_div_by_zero = siginfo->si_code == FPE_INTDIV &&
            _EVOASM_SEARCH_EXCEPTION_SET_P(EVOASM_X64_EXCEPTION_DE);
          jmp = catch_div_by_zero;
          break;
        }
        default:
          break;
      }
      break;
    }
    default: evoasm_assert_not_reached();
  }

  if(jmp) {
    siglongjmp(*((jmp_buf *)&_evoasm_signal_ctx->env), 1);
  } else {
    raise(sig);
  }
}

static void
evoasm_signal_context_install(struct evoasm_signal_context *signal_ctx, evoasm_arch *arch) {
  struct sigaction action = {0};

  signal_ctx->arch_id = arch->cls->id;

  action.sa_sigaction = _evoasm_signal_handler;
  sigemptyset(&action.sa_mask);
  action.sa_flags = SA_SIGINFO;

  if(sigaction(SIGFPE, &action, &signal_ctx->prev_action) < 0) {
    perror("sigaction");
    exit(1);
  }

  _evoasm_signal_ctx = signal_ctx;
  atomic_signal_fence(memory_order_release);
}

static void
evoasm_signal_context_uninstall(struct evoasm_signal_context *signal_ctx) {
  if(sigaction(SIGFPE, &signal_ctx->prev_action, NULL) < 0) {
    perror("sigaction");
    exit(1);
  }
}

#else
#error
#endif

static inline double
evoasm_example_val_to_dbl(evoasm_example_val example_val, evoasm_example_type example_type) {
  switch(example_type) {
    case EVOASM_EXAMPLE_TYPE_F64:
      return example_val.f64;
    case EVOASM_EXAMPLE_TYPE_I64:
      return (double) example_val.i64;
    default:
      evoasm_fatal("unsupported example type %d", example_type);
      evoasm_assert_not_reached();
  }
}

static bool
_evoasm_population_destroy(evoasm_population *pop, bool free_buf, bool free_body_buf) {
  bool retval = true;

  evoasm_prng64_destroy(&pop->prng64);
  evoasm_prng32_destroy(&pop->prng32);
  evoasm_free(pop->programs);
  evoasm_free(pop->fitnesses);
  evoasm_free(pop->output_vals);
  evoasm_free(pop->matching);

  if(free_buf) EVOASM_TRY(buf_free_failed, evoasm_buf_destroy, &pop->buf);

cleanup:
  if(free_body_buf) EVOASM_TRY(body_buf_failed, evoasm_buf_destroy, &pop->body_buf);
  return retval;

buf_free_failed:
  retval = false;
  goto cleanup;

body_buf_failed:
  return false;
}

static evoasm_success
evoasm_population_init(evoasm_population *pop, evoasm_search *search) {
  uint32_t pop_size = search->params.pop_size;
  unsigned i;

  size_t body_buf_size = (size_t) (search->params.max_program_size * search->params.max_kernel_size * search->arch->cls->max_inst_len);
  size_t buf_size = EVOASM_PROGRAM_INPUT_N(&search->params.program_input) * (body_buf_size + EVOASM_SEARCH_PROLOG_EPILOG_SIZE);

  static evoasm_population zero_pop = {0};
  *pop = zero_pop;
  
  size_t program_size = _EVOASM_PROGRAM_SIZE(search->params.max_program_size, search->params.max_kernel_size);

  pop->programs = evoasm_calloc(3 * pop_size, program_size);
  pop->programs_main = pop->programs;
  pop->programs_swap = pop->programs + 1 * search->params.pop_size * program_size;
  pop->programs_aux = pop->programs + 2 * search->params.pop_size * program_size;

  pop->output_vals = evoasm_malloc(EVOASM_PROGRAM_OUTPUT_VALS_SIZE(&search->params.program_input));
  pop->matching = evoasm_malloc(search->params.program_output.arity * sizeof(uint_fast8_t));

  pop->fitnesses = (evoasm_fitness *) evoasm_calloc(pop_size, sizeof(evoasm_fitness));
  for(i = 0; i < EVOASM_SEARCH_ELITE_SIZE; i++) {
    pop->elite[i] = UINT32_MAX;
  }
  pop->elite_pos = 0;
  pop->best_fitness = INFINITY;

  evoasm_prng64_init(&pop->prng64, &search->params.seed64);
  evoasm_prng32_init(&pop->prng32, &search->params.seed32);

  EVOASM_TRY(buf_alloc_failed, evoasm_buf_init, &pop->buf, EVOASM_BUF_TYPE_MMAP, buf_size);
  EVOASM_TRY(body_buf_alloc_failed, evoasm_buf_init, &pop->body_buf, EVOASM_BUF_TYPE_MALLOC, body_buf_size);

  EVOASM_TRY(prot_failed, evoasm_buf_protect, &pop->buf,
      EVOASM_MPROT_RWX);

  return true;

buf_alloc_failed:
  _evoasm_population_destroy(pop, false, false);
  return false;

body_buf_alloc_failed:
  _evoasm_population_destroy(pop, true, false);
  return false;

prot_failed:
  _evoasm_population_destroy(pop, true, true);
  return false;
}

static evoasm_success
evoasm_population_destroy(evoasm_population *pop) {
  return _evoasm_population_destroy(pop, true, true);
}

#define EVOASM_SEARCH_X64_REG_TMP EVOASM_X64_REG_14


static void
evoasm_program_x64_output_regs(evoasm_program *program, evoasm_reg_id *output_regs, size_t *len) {
  unsigned i, reg_idx;
  evoasm_kernel *kernel = &program->kernels[program->params->size - 1];

  for(i = 0, reg_idx = 0; reg_idx < kernel->n_output_regs; i++) {
    if(!kernel->reg_info.x64[i].output) continue;
    output_regs[reg_idx] = (evoasm_reg_id) i;
    reg_idx++;
  }
  
  *len = reg_idx;
}


void
evoasm_program_output_regs(evoasm_program *program, evoasm_reg_id *output_regs, size_t *len) {
  switch(program->arch->cls->id) {
    case EVOASM_ARCH_X64: {
      evoasm_program_x64_output_regs(program, output_regs, len);
      break;
    }
    default:
      evoasm_assert_not_reached();
  }
}

static evoasm_success
evoasm_program_x64_emit_output_save(evoasm_program *program,
                                    unsigned example_index) {
  evoasm_arch *arch = program->arch;
  evoasm_x64 *x64 = (evoasm_x64 *) arch;
  evoasm_x64_params params = {0};
  evoasm_kernel *kernel = &program->kernels[program->params->size - 1];
  unsigned i, reg_idx;

  for(i = 0, reg_idx = 0; reg_idx < kernel->n_output_regs; i++) {
    if(!kernel->reg_info.x64[i].output) continue;
    
    evoasm_example_val *val_addr = &program->output_vals[(kernel->n_output_regs * example_index) + reg_idx];
    evoasm_x64_reg_id reg_id = i;
    enum evoasm_x64_reg_type reg_type = evoasm_x64_reg_type(reg_id);

    evoasm_arch_param_val addr_imm = (evoasm_arch_param_val)(uintptr_t) val_addr;

    EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, EVOASM_SEARCH_X64_REG_TMP);
    EVOASM_X64_SET(EVOASM_X64_PARAM_IMM0, addr_imm);
    EVOASM_X64_ENC(mov_r64_imm64);
    evoasm_arch_save(arch, program->buf);

    switch(reg_type) {
      case EVOASM_X64_REG_TYPE_GP: {
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG1, reg_id);
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG_BASE, EVOASM_SEARCH_X64_REG_TMP);
        EVOASM_X64_ENC(mov_rm64_r64);
        evoasm_arch_save(arch, program->buf);
        break;
      }
      case EVOASM_X64_REG_TYPE_XMM: {
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG1, reg_id);
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG_BASE, EVOASM_SEARCH_X64_REG_TMP);
        EVOASM_X64_ENC(movsd_xmmm64_xmm);
        evoasm_arch_save(arch, program->buf);
        break;
      }
      default: {
        evoasm_assert_not_reached();
      }

    }
    
    reg_idx++;
  }

  return true;

enc_failed:
  return false;
}

static void
evoasm_search_seed_kernel_param(evoasm_search *search, evoasm_kernel_param *kernel_param) {
  unsigned i;
  int64_t inst_idx = evoasm_prng64_rand_between(&search->pop.prng64, 0, search->params.insts_len - 1);
  evoasm_inst *inst = search->params.insts[inst_idx];

  kernel_param->inst = inst;

  /* set parameters */
  for(i = 0; i < search->params.params_len; i++) {
    evoasm_domain *domain = &search->domains[inst_idx * search->params.params_len + i];
    if(domain->type < EVOASM_N_DOMAIN_TYPES) {
      evoasm_arch_param_id param_id = search->params.params[i];
      evoasm_arch_param_val param_val;

      param_val = (evoasm_arch_param_val) evoasm_domain_rand(domain, &search->pop.prng64);
      evoasm_arch_params_set(
          kernel_param->param_vals,
          (evoasm_bitmap *) &kernel_param->set_params,
          param_id,
          param_val
      );
    }
  }
}


static void
evoasm_search_seed_kernel(evoasm_search *search, evoasm_kernel_params *kernel_params,
                          evoasm_program_size program_size) {
  unsigned i;

  evoasm_kernel_size kernel_size = (evoasm_kernel_size) evoasm_prng32_rand_between(&search->pop.prng32,
     search->params.min_kernel_size, search->params.max_kernel_size);

  assert(kernel_size > 0);
  kernel_params->size = kernel_size;
  kernel_params->jmp = (uint8_t) evoasm_prng32_rand_between(&search->pop.prng32, 0, UINT8_MAX);
  kernel_params->branch_kernel_idx = (evoasm_kernel_size) 
    evoasm_prng32_rand_between(&search->pop.prng32, 0, program_size - 1);

  for(i = 0; i < kernel_size; i++) {
    evoasm_search_seed_kernel_param(search, &kernel_params->params[i]);
  }
}


static void
evoasm_search_seed_program(evoasm_search *search, unsigned char *programs, unsigned program_index) {
  unsigned i;

  evoasm_program_params *program_params = _EVOASM_SEARCH_PROGRAM_PARAMS(search, programs, program_index);
  evoasm_program_size program_size = (evoasm_program_size) evoasm_prng64_rand_between(&search->pop.prng64,
     search->params.min_program_size, search->params.max_program_size);

  assert(program_size > 0);
  program_params->size = program_size;
  
  for(i = 0; i < program_size; i++) {
    evoasm_kernel_params *kernel_params = _EVOASM_PROGRAM_PARAMS_KERNEL_PARAMS(program_params, search->params.max_kernel_size, i);
    evoasm_search_seed_kernel(search, kernel_params, program_size);
  }

}


static void
evoasm_search_seed(evoasm_search *search, unsigned char *programs) {
  unsigned i;

  for(i = 0; i < search->params.pop_size; i++) {
    evoasm_search_seed_program(search, programs, i);
  }
}


static evoasm_success
evoasm_program_x64_emit_rflags_reset(evoasm_program *program) {
  evoasm_x64 *x64 = (evoasm_x64 *) program->arch;
  evoasm_x64_params params = {0};

  evoasm_debug("emitting RFLAGS reset");
  EVOASM_X64_ENC(pushfq);
  evoasm_arch_save(program->arch, program->buf);
  EVOASM_X64_SET(EVOASM_X64_PARAM_REG_BASE, EVOASM_X64_REG_SP);
  EVOASM_X64_SET(EVOASM_X64_PARAM_IMM, 0);
  EVOASM_X64_ENC(mov_rm64_imm32);
  evoasm_arch_save(program->arch, program->buf);
  EVOASM_X64_ENC(popfq);
  evoasm_arch_save(program->arch, program->buf);

  return true;
enc_failed:
  return false;
}

static evoasm_success
evoasm_search_x64_emit_mxcsr_reset(evoasm_search *search, evoasm_buf *buf) {
  evoasm_arch *arch = search->arch;
  static uint32_t default_mxcsr_val = 0x1f80;
  evoasm_x64 *x64 = (evoasm_x64 *) arch;
  evoasm_x64_params params = {0};
  evoasm_arch_param_val addr_imm = (evoasm_arch_param_val)(uintptr_t) &default_mxcsr_val;

  evoasm_x64_reg_id reg_tmp0 = EVOASM_X64_REG_14;

  EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, reg_tmp0);
  EVOASM_X64_SET(EVOASM_X64_PARAM_IMM0, addr_imm);
  EVOASM_X64_ENC(mov_r32_imm32);
  evoasm_arch_save(arch, buf);

  EVOASM_X64_SET(EVOASM_X64_PARAM_REG_BASE, reg_tmp0);
  EVOASM_X64_ENC(ldmxcsr_m32);
  evoasm_arch_save(arch, buf);

  return true;
enc_failed:
  return false;
}


static evoasm_x64_reg_id
evoasm_op_x64_reg_id(evoasm_x64_operand *op, evoasm_kernel_param *param) {
  evoasm_inst *inst = param->inst;

  if(op->param_idx < inst->params_len) {
    return (evoasm_x64_reg_id) param->param_vals[inst->params[op->param_idx].id];
  } else if(op->reg_id < EVOASM_X64_N_REGS) {
    return op->reg_id;
  } else {
    evoasm_assert_not_reached();
    return 0;
  }
}

static void
evoasm_program_x64_prepare_kernel(evoasm_program *program, evoasm_kernel *kernel) {
  unsigned i, j;

  kernel->n_input_regs = 0;
  kernel->n_output_regs = 0;
   
  /* NOTE: output register are register that are written to
   *       input registers are register that are read from without
   *       a previous write 
   */
  evoasm_kernel_params *kernel_params = kernel->params;

  for(i = 0; i < kernel_params->size; i++) {
    evoasm_kernel_param *param = &kernel_params->params[i];
    evoasm_x64_inst *x64_inst = (evoasm_x64_inst *) param->inst;
    bool l8 = param->param_vals[EVOASM_X64_PARAM_REX_B] ||
              param->param_vals[EVOASM_X64_PARAM_REX_R] ||
              param->param_vals[EVOASM_X64_PARAM_REX_W] ||
              param->param_vals[EVOASM_X64_PARAM_REX_X];
    bool h8 = !l8;
    

    for(j = 0; j < x64_inst->n_operands; j++) {
      evoasm_x64_operand *op = &x64_inst->operands[j];
      
      if(op->type == EVOASM_X64_OPERAND_TYPE_REG ||
         op->type == EVOASM_X64_OPERAND_TYPE_RM) {
        evoasm_x64_reg_id reg_id;

        if(op->reg_type == EVOASM_X64_REG_TYPE_RFLAGS) {
          if(op->acc_r) {
            program->reset_rflags = true;
          } else if(op->acc_w) {
            kernel->reg_info.x64[op->reg_id].written = true;
          }
        }
        else {
          reg_id = evoasm_op_x64_reg_id(op, param);
          evoasm_kernel_x64_reg_info *reg_info = &kernel->reg_info.x64[reg_id];


          /*
           * Conditional writes (acc_c) might or might not do the write.
           */

          if(op->acc_r || op->acc_c) {
            if(!reg_info->input) {
              // has not been written before, might contain garbage
              bool dirty_read;
              
              if(!reg_info->written) {
                dirty_read = true;
              } else {
                if(op->reg_type == EVOASM_X64_REG_TYPE_GP) {
                  if(op->size == EVOASM_OPERAND_SIZE_8) {
                    dirty_read = reg_info->l8 != l8 && reg_info->h8 != h8;
                  } else if(op->size == EVOASM_OPERAND_SIZE_16) {
                    dirty_read = reg_info->size < EVOASM_OPERAND_SIZE_16;
                  } else {
                    dirty_read = false;
                  }
                } else if(op->reg_type == EVOASM_X64_REG_TYPE_XMM) {
                  int mask;
                  if(op->size == EVOASM_OPERAND_SIZE_128) {
                    mask = EVOASM_X64_BIT_MASK_0_127;
                  } else {
                    mask = EVOASM_X64_BIT_MASK_ALL;
                  }
                  dirty_read = (mask & (~reg_info->mask)) != 0;
                } else {
                  dirty_read = false;
                }
              }

              if(dirty_read) {
                reg_info->input = true;
                kernel->n_input_regs++;
              }
            }
          }

          if(op->acc_w) {
            // ???
            //evoasm_operand_size reg_size = (evoasm_operand_size) EVOASM_MIN(output_sizes[program->n_output_regs],
            //    op->acc_c ? EVOASM_N_OPERAND_SIZES : op->size);

            if(!reg_info->written) {
              reg_info->written = true;
              reg_info->output = true;
              reg_info->size = op->size;
              kernel->n_output_regs++;
            } else {
              reg_info->size = (unsigned) EVOASM_MAX(reg_info->size, op->size);
            }
            reg_info->mask |= op->acc_w_mask;
            reg_info->l8 |= l8;
            reg_info->h8 |= h8;
          }
        }
      }
    }
  }

  assert(kernel->n_output_regs <= EVOASM_KERNEL_MAX_OUTPUT_REGS);
  assert(kernel->n_input_regs <= EVOASM_KERNEL_MAX_INPUT_REGS);

}

static void
evoasm_program_x64_prepare(evoasm_program *program) {
  unsigned i;
  for(i = 0; i < program->params->size; i++) {
    evoasm_kernel *kernel = &program->kernels[i];
    evoasm_program_x64_prepare_kernel(program, kernel);
  }

}

static evoasm_success
evoasm_program_x64_emit_program_prolog(evoasm_program *program,
                                       evoasm_example_val *input_vals,
                                       evoasm_example_type *types,
                                       unsigned in_arity) {


  evoasm_x64 *x64 = (evoasm_x64 *) program->arch;
  unsigned i, reg_idx;
  evoasm_example_val *loaded_example = NULL;
  evoasm_kernel *kernel = &program->kernels[0];

  // FIXME: handle case where there are more inputs
  // than input registers
  for(i = 0, reg_idx = 0; reg_idx < kernel->n_input_regs; i++) {
    if(!kernel->reg_info.x64[i].input) continue;

    unsigned example_idx = reg_idx % in_arity;
    evoasm_example_val *example = &input_vals[example_idx];
    //evoasm_example_type type = types[i];
    evoasm_x64_reg_id reg_id = i;
    evoasm_x64_params params = {0};
    enum evoasm_x64_reg_type reg_type = evoasm_x64_reg_type(reg_id);

    evoasm_debug("emitting input register initialization of register %d to value %" PRId64, reg_id, example->i64);

    switch(reg_type) {
      case EVOASM_X64_REG_TYPE_GP: {
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, reg_id);
        /*FIXME: hard-coded example type */
        EVOASM_X64_SET(EVOASM_X64_PARAM_IMM0, (evoasm_arch_param_val) example->i64);
        EVOASM_X64_ENC(mov_r64_imm64);
        evoasm_arch_save(program->arch, program->buf);
        break;
      }
      case EVOASM_X64_REG_TYPE_XMM: {
        
        /* load address of example into tmp_reg */
        if(loaded_example != example) {
          EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, EVOASM_SEARCH_X64_REG_TMP);
          EVOASM_X64_SET(EVOASM_X64_PARAM_IMM0, (evoasm_arch_param_val)(uintptr_t) &example->f64);
          EVOASM_X64_ENC(mov_r64_imm64);
          loaded_example = example;
        }

        /* load into xmm via address in tmp_reg */
        /*FIXME: hard-coded example type */
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, reg_id);
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG_BASE, EVOASM_SEARCH_X64_REG_TMP);
        EVOASM_X64_ENC(movsd_xmm_xmmm64);
        evoasm_arch_save(program->arch, program->buf);
        break;
      }
      default:
        evoasm_fatal("non-gpr register type (%d) (unimplemented)", reg_type);
        evoasm_assert_not_reached();
    }
    
    reg_idx++;
  }

  if(program->reset_rflags) {
    EVOASM_TRY(error, evoasm_program_x64_emit_rflags_reset, program);
  }
  return true;

error:
enc_failed:
  return false;
}

static evoasm_success
evoasm_program_x64_emit_kernel_transition(evoasm_program *program,
                                          evoasm_kernel *kernel,
                                          evoasm_kernel *target_kernel,
                                          evoasm_buf *buf) {
  evoasm_arch *arch = program->arch;
  evoasm_x64 *x64 = (evoasm_x64 *) arch;
  unsigned i, reg_idx;
  unsigned output_reg_idcs[EVOASM_X64_N_REGS];
  
  for(i = 0, reg_idx = 0; i < EVOASM_X64_N_REGS; i++) {
    if(!kernel->reg_info.x64[i].output) continue;
    output_reg_idcs[reg_idx++] = i;
  }

  for(i = 0, reg_idx = 0; i < EVOASM_X64_N_REGS; i++) {
    if(!target_kernel->reg_info.x64[i].input) continue;

    unsigned output_reg_idx = reg_idx % target_kernel->n_input_regs;
    evoasm_x64_reg_id input_reg_id = i;
    enum evoasm_x64_reg_type input_reg_type = evoasm_x64_reg_type(input_reg_id);

    evoasm_x64_reg_id output_reg_id = (evoasm_x64_reg_id) output_reg_idcs[output_reg_idx];
    enum evoasm_x64_reg_type output_reg_type = evoasm_x64_reg_type(output_reg_id);

    evoasm_x64_params params = {0};

    if(input_reg_id != output_reg_id) {
      if(output_reg_type == EVOASM_X64_REG_TYPE_GP &&
         input_reg_type == EVOASM_X64_REG_TYPE_GP) {
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, input_reg_id);
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG1, output_reg_id);
        EVOASM_X64_ENC(mov_r64_rm64);
        evoasm_arch_save(program->arch, buf);
      }
      else if(output_reg_type == EVOASM_X64_REG_TYPE_XMM &&
                input_reg_type == EVOASM_X64_REG_TYPE_XMM) {
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, input_reg_id);
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG1, output_reg_id);
        if(x64->features & EVOASM_X64_FEATURE_AVX) {
          EVOASM_X64_ENC(vmovdqa_ymm_ymmm256);
        }
        else {
          EVOASM_X64_ENC(movdqa_xmm_xmmm128);
        }
        evoasm_arch_save(program->arch, buf);
      }
      else if(output_reg_type == EVOASM_X64_REG_TYPE_GP &&
              input_reg_type == EVOASM_X64_REG_TYPE_XMM) {
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, input_reg_id);
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG1, output_reg_id);
        if(x64->features & EVOASM_X64_FEATURE_AVX) {
          EVOASM_X64_ENC(vmovq_xmm_rm64);
        } else {
          EVOASM_X64_ENC(movq_xmm_rm64);
        }
        evoasm_arch_save(program->arch, buf);
      }
      else if(output_reg_type == EVOASM_X64_REG_TYPE_XMM &&
              input_reg_type == EVOASM_X64_REG_TYPE_GP) {
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, input_reg_id);
        EVOASM_X64_SET(EVOASM_X64_PARAM_REG1, output_reg_id);
        if(x64->features & EVOASM_X64_FEATURE_AVX) {
          EVOASM_X64_ENC(vmovq_rm64_xmm);
        } 
        else {
          EVOASM_X64_ENC(movq_rm64_xmm);
        }
        evoasm_arch_save(program->arch, buf);
      } 
      else {
        evoasm_assert_not_reached();
      }
    }
    reg_idx++;
  }
  
  return true;
  
enc_failed:
    return false;  
}

#define _EVOASM_BUF_PHI_GET(buf) ((uint32_t *)((buf)->data + (buf)->pos - 4))
#define _EVOASM_BUF_PHI_SET(label, val) \
do { (*(label) = (uint32_t)((uint8_t *)(val) - ((uint8_t *)(label) + 4)));} while(0);
#define _EVOASM_BUF_POS_ADDR(buf) (buf->data + buf->pos)

static evoasm_success
evoasm_program_x64_emit_kernel_epilog(evoasm_program *program,
                                      evoasm_kernel *kernel,
                                      evoasm_kernel *next_kernel,
                                      evoasm_kernel *branch_kernel,
                                      evoasm_buf *buf,
                                      uint32_t **branch_kernel_phi) {

  evoasm_arch *arch = program->arch;
  evoasm_x64 *x64 = (evoasm_x64 *) arch;
  unsigned jmp_insts_len = 0;
  evoasm_inst_id jmp_insts[32];
  bool jbe = false;
  bool jle = false;
  evoasm_x64_params params = {0};
  uint32_t *branch_phi = NULL;
  uint32_t *counter_phi = NULL;

  if(kernel->reg_info.x64[EVOASM_X64_REG_OF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JO_REL32;
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JNO_REL32;
  }
  
  if(kernel->reg_info.x64[EVOASM_X64_REG_SF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JS_REL32;
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JNS_REL32;
  }
  
  if(kernel->reg_info.x64[EVOASM_X64_REG_ZF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JE_JZ_REL32;
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JNS_REL32;

    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JBE_JNA_REL32;
    jbe = true;

    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JLE_JNG_REL32;
    jle = true;
  }  
  
  if(kernel->reg_info.x64[EVOASM_X64_REG_CF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JB_JC_JNAE_REL32;
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JAE_JNB_JNC_REL32;
    
    if(!jbe) {
      jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JBE_JNA_REL32;
    }
  }
  
  if(kernel->reg_info.x64[EVOASM_X64_REG_ZF].written &&
     kernel->reg_info.x64[EVOASM_X64_REG_CF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JA_JNBE_REL32;    
  }
  
  if(kernel->reg_info.x64[EVOASM_X64_REG_SF].written &&
     kernel->reg_info.x64[EVOASM_X64_REG_OF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JL_JNGE_REL32;
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JGE_JNL_REL32;
    
    if(!jle) {
      jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JLE_JNG_REL32;
    }
    
    if(kernel->reg_info.x64[EVOASM_X64_REG_ZF].written) {
      jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JG_JNLE_REL32;
    }
  }  
  
  if(kernel->reg_info.x64[EVOASM_X64_REG_CF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JB_JC_JNAE_REL32;
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JAE_JNB_JNC_REL32;
  }  
  
  if(kernel->reg_info.x64[EVOASM_X64_REG_PF].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JP_JPE_REL32;
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JNP_JPO_REL32;
  } 

#if 0 
  /*FIXME: only 8bit possible, check and activate if feasable*/
  if(kernel->reg_info.x64[EVOASM_X64_REG_C].written) {
    jmp_insts[jmp_insts_len++] = EVOASM_X64_INST_JECXZ_JRCXZ_REL8;
  }
#endif 

  if(jmp_insts_len > 0) {
    evoasm_inst_id jmp_inst_id = jmp_insts[kernel->params->jmp % jmp_insts_len];
    evoasm_inst *jmp_inst = (evoasm_inst *) evoasm_x64_get_inst(x64, jmp_inst_id, false);

    EVOASM_X64_SET(EVOASM_X64_PARAM_REL, 0xdeadbeef);
    EVOASM_TRY(error, evoasm_inst_encode, jmp_inst, arch, params.vals, (evoasm_bitmap *) &params.set);
    evoasm_arch_save(arch, buf);
    branch_phi = _EVOASM_BUF_PHI_GET(buf);
    assert(*branch_phi == 0xdeadbeef);
  
    if(branch_kernel->idx <= kernel->idx) {
      /* back jump, guard with counter */
    
      uint32_t *counter = &program->recur_counters[kernel->idx];
      uintptr_t addr_imm = (uintptr_t) counter;

      EVOASM_X64_SET(EVOASM_X64_PARAM_REG0, EVOASM_SEARCH_X64_REG_TMP);
      EVOASM_X64_SET(EVOASM_X64_PARAM_IMM0, (evoasm_arch_param_val) addr_imm);
      EVOASM_X64_ENC(mov_r64_imm64);
      evoasm_arch_save(arch, buf);
    
      EVOASM_X64_SET(EVOASM_X64_PARAM_REG_BASE, EVOASM_SEARCH_X64_REG_TMP);
      EVOASM_X64_SET(EVOASM_X64_PARAM_IMM0, program->max_recur);
      EVOASM_X64_ENC(cmp_rm32_imm32);
      evoasm_arch_save(arch, buf);

      EVOASM_X64_SET(EVOASM_X64_PARAM_REL, 0xdeadbeef);
      EVOASM_X64_ENC(jge_jnl_rel32);
      evoasm_arch_save(arch, buf);
      counter_phi = _EVOASM_BUF_PHI_GET(buf);
      assert(*counter_phi == 0xdeadbeef);
      
      EVOASM_X64_ENC(inc_rm32);
      evoasm_arch_save(arch, buf);
    }
    
    EVOASM_TRY(error, evoasm_program_x64_emit_kernel_transition, program,
               kernel, branch_kernel, buf);
               
    EVOASM_X64_SET(EVOASM_X64_PARAM_REL, 0xdeadbeef);
    EVOASM_X64_ENC(jmp_rel32);
    evoasm_arch_save(arch, buf);
    *branch_kernel_phi = _EVOASM_BUF_PHI_GET(buf);
    assert(**branch_kernel_phi == 0xdeadbeef);
  }

  if(branch_phi != NULL) {
    _EVOASM_BUF_PHI_SET(branch_phi, _EVOASM_BUF_POS_ADDR(buf));
  }
  
  if(counter_phi != NULL) {
    _EVOASM_BUF_PHI_SET(counter_phi, _EVOASM_BUF_POS_ADDR(buf));
  }
  
  if(next_kernel != NULL) {
    EVOASM_TRY(error, evoasm_program_x64_emit_kernel_transition, program,
              kernel, next_kernel, buf);
  }
  
  evoasm_buf_log(buf, EVOASM_LOG_LEVEL_INFO);
 
  return true;

error:
enc_failed:
  return false;
}


static evoasm_success
evoasm_program_x64_emit_kernel(evoasm_program *program, evoasm_kernel *kernel, evoasm_buf *buf) {
  unsigned i;
  evoasm_arch *arch = program->arch;
  evoasm_kernel_params *kernel_params = kernel->params;

  assert(kernel_params->size > 0);
  for(i = 0; i < kernel_params->size; i++) {
    evoasm_inst *inst = kernel_params->params[i].inst;
    evoasm_x64_inst *x64_inst = (evoasm_x64_inst *) inst;
    program->exception_mask = program->exception_mask | x64_inst->exceptions;
    EVOASM_TRY(error, evoasm_inst_encode,
                      inst,
                      arch,
                      kernel_params->params[i].param_vals,
                      (evoasm_bitmap *) &kernel_params->params[i].set_params);

    evoasm_arch_save(arch, buf);
  }
  return true;
error:
  return false;
}


static evoasm_success
evoasm_program_x64_emit_program_body(evoasm_program *program) {
  unsigned i;
  evoasm_buf *buf = program->body_buf;
  evoasm_program_params *program_params = program->params;
  evoasm_kernel *kernel, *next_kernel, *branch_kernel;
  unsigned size = program_params->size;
  uint32_t *branch_phis[EVOASM_PROGRAM_MAX_SIZE] = {0};
  uint8_t *kernel_addrs[EVOASM_PROGRAM_MAX_SIZE];

  evoasm_buf_reset(buf);

  assert(size > 0);
  for(i = 0; i < size; i++) {
    kernel = &program->kernels[i];
    
    kernel_addrs[i] = buf->data + buf->pos;
    EVOASM_TRY(error, evoasm_program_x64_emit_kernel, program, kernel, buf);

    if(i < size - 1) {
      next_kernel = &program->kernels[i + 1];
    } else {
      next_kernel = NULL;
    }
    
    assert(kernel->params->branch_kernel_idx < program->params->size);
    branch_kernel = &program->kernels[kernel->params->branch_kernel_idx];
    
    EVOASM_TRY(error, evoasm_program_x64_emit_kernel_epilog, program, kernel,
      next_kernel, branch_kernel, buf, &branch_phis[i]);      
  }
  
  for(i = 0; i < size; i++) {
    uint32_t *branch_phi = branch_phis[i];
    if(branch_phi != NULL) {
      kernel = &program->kernels[i];
      uint8_t *branch_kernel_addr = kernel_addrs[kernel->params->branch_kernel_idx];
      assert(*branch_phi == 0xdeadbeef);
      _EVOASM_BUF_PHI_SET(branch_phi, branch_kernel_addr);
    }
  }

  return true;
error:
  return false;
}

static evoasm_success
evoasm_program_x64_emit_sandbox(evoasm_program *program,
                                evoasm_program_input *input) {
  unsigned i;
  unsigned n_examples = EVOASM_PROGRAM_INPUT_N(input);

  evoasm_buf_reset(program->buf);

  EVOASM_TRY(error, evoasm_x64_func_prolog, (evoasm_x64 *) program->arch, program->buf, EVOASM_X64_ABI_SYSV);

  for(i = 0; i < n_examples; i++) {
    evoasm_example_val *input_vals = input->vals + i * input->arity;
    evoasm_debug("emitting program %d for example %d", program->index, i);
    EVOASM_TRY(error, evoasm_program_x64_emit_program_prolog, program, input_vals, input->types, input->arity);
    {
      size_t r = evoasm_buf_append(program->buf, program->body_buf);
      assert(r == 0);
    }
    EVOASM_TRY(error, evoasm_program_x64_emit_output_save, program, i);
  }

  EVOASM_TRY(error, evoasm_x64_func_epilog, (evoasm_x64 *) program->arch, program->buf, EVOASM_X64_ABI_SYSV);
  return true;

error:
  return false;
}

static evoasm_success
evoasm_program_x64_emit(evoasm_program *program,
                       evoasm_program_input *input,
                       bool prepare, bool body, bool sandbox) {
                         
  if(prepare) {
    evoasm_program_x64_prepare(program);
  }
                         
  if(body) {
    EVOASM_TRY(error, evoasm_program_x64_emit_program_body, program);
  }

  if(sandbox) {
    EVOASM_TRY(error, evoasm_program_x64_emit_sandbox, program, input);
  }
  
  evoasm_buf_log(program->buf, EVOASM_LOG_LEVEL_INFO);


  return true;

error:
  return false;
}

static evoasm_success
evoasm_program_emit(evoasm_program *program,
                   evoasm_program_input *input,
                   bool setup, bool body, bool sandbox) {
  evoasm_arch *arch = program->arch;

  switch(arch->cls->id) {
    case EVOASM_ARCH_X64: {
      return evoasm_program_x64_emit(program, input,
                                    setup, body, sandbox);
      break;
    }
    default:
      evoasm_assert_not_reached();
  }
}

typedef enum {
  EVOASM_METRIC_ABSDIFF,
  EVOASM_N_METRICS
} evoasm_metric;

static inline void
evoasm_program_update_dist_mat(evoasm_program *program,
                               evoasm_kernel *kernel,
                               evoasm_program_output *output,
                               unsigned height,
                               unsigned example_index,
                               double *matrix,
                               evoasm_metric metric) {
  unsigned i, j;
  unsigned width = kernel->n_output_regs;
  evoasm_example_val *example_vals = output->vals + example_index * output->arity;

  for(i = 0; i < height; i++) {
    evoasm_example_val example_val = example_vals[i];
    evoasm_example_type example_type = output->types[i];
    double example_val_dbl = evoasm_example_val_to_dbl(example_val, example_type);

    for(j = 0; j < width; j++) {
      evoasm_example_val output_val = program->output_vals[example_index * width + j];
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
      double output_val_dbl = evoasm_example_val_to_dbl(output_val, example_type);

      switch(metric) {
        default:
        case EVOASM_METRIC_ABSDIFF: {
          double dist = fabs(output_val_dbl - example_val_dbl);
          matrix[i * width + j] += dist;
          break;
        }
      }
    }
  }
}

static void
evoasm_program_log_program_output(evoasm_program *program,
                                  evoasm_kernel *kernel,
                                  evoasm_program_output *output,
                                  uint_fast8_t *matching,
                                  evoasm_log_level log_level) {

  unsigned n_examples = EVOASM_PROGRAM_OUTPUT_N(output);
  unsigned height = output->arity;
  unsigned width = kernel->n_output_regs;
  unsigned i, j, k;

  evoasm_log(log_level, EVOASM_LOG_TAG, "OUTPUT MATRICES:\n");
  for(i = 0; i < n_examples; i++) {
    for(j = 0; j < height; j++) {
      for(k = 0; k < width; k++) {
        bool matched = matching[j] == k;
        evoasm_example_val val = program->output_vals[i * width + k];
        if(matched) {
          evoasm_log(log_level, EVOASM_LOG_TAG, " \x1b[1m ");
        }
        evoasm_log(log_level, EVOASM_LOG_TAG, " %ld (%f)\t ", val.i64, val.f64);
        if(matched) {
          evoasm_log(log_level, EVOASM_LOG_TAG, " \x1b[0m ");
        }
      }
      evoasm_log(log_level, EVOASM_LOG_TAG, " \n ");
    }
    evoasm_log(log_level, EVOASM_LOG_TAG, " \n\n ");
  }
}

static void
evoasm_program_log_dist_matrix(evoasm_program *program,
                               evoasm_kernel *kernel,
                               unsigned height,
                               double *matrix,
                               uint_fast8_t *matching,
                               evoasm_log_level log_level) {

  unsigned width = kernel->n_output_regs;
  unsigned i, j;

  evoasm_log(log_level, EVOASM_LOG_TAG, "DIST MATRIX: (%d, %d)\n", height, width);
  for(i = 0; i < height; i++) {
    for(j = 0; j < width; j++) {
      if(matching[i] == j) {
        evoasm_log(log_level, EVOASM_LOG_TAG, " \x1b[1m ");
      }
      evoasm_log(log_level, EVOASM_LOG_TAG, " %.2g\t ", matrix[i * width + j]);
      if(matching[i] == j) {
        evoasm_log(log_level, EVOASM_LOG_TAG, " \x1b[0m ");
      }
    }
    evoasm_log(log_level, EVOASM_LOG_TAG, " \n ");
  }
  evoasm_log(log_level, EVOASM_LOG_TAG, " \n\n ");
}


static inline bool
evoasm_program_find_min_dist(evoasm_program *program,
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

  if(EVOASM_LIKELY(best_index != UINT_FAST8_MAX)) {
    *matching = best_index;
    return true;
  } else {
    /*evoasm_program_log_dist_matrix(program,
                                  1,
                                  matrix,
                                  matching,
                                  EVOASM_LOG_LEVEL_WARN);
    evoasm_assert_not_reached();*/
    /*
     * Might happen if all elements are inf or nan
     */
    return false;
  }
}

static inline void
evoasm_program_calc_stable_matching(evoasm_program *program,
                                    evoasm_kernel *kernel,
                                   unsigned height,
                                   double *matrix,
                                   uint_fast8_t *matching) {

  uint_fast8_t width =  (uint_fast8_t) kernel->n_output_regs;
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

    if(EVOASM_LIKELY(best_index != UINT_FAST8_MAX)) {
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
      evoasm_program_log_dist_matrix(program,
                                    kernel,
                                    height,
                                    matrix,
                                    matching,
                                    EVOASM_LOG_LEVEL_DEBUG);
      evoasm_assert_not_reached();
    }
  }
}


static inline evoasm_fitness
evoasm_program_calc_fitness(evoasm_program *program,
                            evoasm_kernel *kernel,
                           unsigned height,
                           double *matrix,
                           uint_fast8_t *matching) {
  unsigned i;
  unsigned width = kernel->n_output_regs;
  double scale = 1.0 / width;
  evoasm_fitness fitness = 0.0;

  for(i = 0; i < height; i++) {
    fitness += scale * matrix[i * width + matching[i]];
  }

  return fitness;
}

static evoasm_fitness
evoasm_program_assess(evoasm_program *program,
                     evoasm_program_output *output,
                     uint_fast8_t *matching) {

  unsigned i;
  unsigned n_examples = EVOASM_PROGRAM_OUTPUT_N(output);
  unsigned height = output->arity;
  evoasm_kernel *kernel = &program->kernels[program->params->size - 1];
  unsigned width =  kernel->n_output_regs;
  size_t matrix_len = (size_t)(width * height);
  double *matrix = alloca(matrix_len * sizeof(double));
  evoasm_fitness fitness;

  for(i = 0; i < matrix_len; i++) {
    matrix[i] = 0.0;
  }

  if(height == 1) {
    /* COMMON FAST-PATH */
    for(i = 0; i < n_examples; i++) {
      evoasm_program_update_dist_mat(program, kernel, output, 1, i, matrix, EVOASM_METRIC_ABSDIFF);
    }

    if(evoasm_program_find_min_dist(program, width, matrix, matching)) {
      fitness = evoasm_program_calc_fitness(program, kernel, 1, matrix, matching);
    } else {
      fitness = INFINITY;
    }
  }
  else {
    for(i = 0; i < n_examples; i++) {
      evoasm_program_update_dist_mat(program, kernel, output, height, i, matrix, EVOASM_METRIC_ABSDIFF);
    }

    evoasm_program_calc_stable_matching(program, kernel, height, matrix, matching);
    fitness = evoasm_program_calc_fitness(program, kernel, height, matrix, matching);
  }

#if EVOASM_MIN_LOG_LEVEL <= EVOASM_LOG_LEVEL_DEBUG
  if(fitness == 0.0) {
    evoasm_program_log_program_output(program,
                                      kernel,
                                      output,
                                      matching,
                                      EVOASM_LOG_LEVEL_DEBUG);
  }
#endif

  return fitness;
}

static void
evoasm_program_load_output(evoasm_program *program,
                           evoasm_kernel *kernel,
                           evoasm_program_input *input,
                           evoasm_program_output *output,
                           uint_fast8_t *matching,
                           evoasm_program_output *loaded_output) {

  unsigned i, j;
  unsigned width = kernel->n_output_regs;
  unsigned height = output->arity;
  unsigned n_examples = EVOASM_PROGRAM_INPUT_N(input);

  loaded_output->len = (uint16_t)(EVOASM_PROGRAM_INPUT_N(input) * height);
  loaded_output->vals = evoasm_malloc((size_t) loaded_output->len * sizeof(evoasm_example_val));

  for(i = 0; i < n_examples; i++) {
    for(j = 0; j < height; j++) {
      loaded_output->vals[i * height + j] = program->output_vals[i * width + matching[j]];
    }
  }

  loaded_output->arity = output->arity;
  memcpy(loaded_output->types, output->types, EVOASM_ARY_LEN(output->types));

//#if EVOASM_MIN_LOG_LEVEL <= EVOASM_LOG_LEVEL_INFO
  evoasm_program_log_program_output(program,
                                    kernel,
                                    loaded_output,
                                    matching,
                                    EVOASM_LOG_LEVEL_WARN);
//#endif
}

void
evoasm_program_io_destroy(evoasm_program_io *program_io) {
  evoasm_free(program_io->vals);
}

evoasm_success
evoasm_program_run(evoasm_program *program,
                  evoasm_program_input *input,
                  evoasm_program_output *output) {
  bool retval;
  struct evoasm_signal_context signal_ctx = {0};
  unsigned i;
  evoasm_kernel *kernel = &program->kernels[program->params->size - 1];

  if(input->arity != program->_input.arity) {
    evoasm_set_error(EVOASM_ERROR_TYPE_ARGUMENT, EVOASM_ERROR_CODE_NONE, NULL,
        "example arity mismatch (%d for %d)", input->arity, program->_input.arity);
    return false;
  }

  for(i = 0; i < input->arity; i++) {
    if(input->types[i] != program->_input.types[i]) {
       evoasm_set_error(EVOASM_ERROR_TYPE_ARGUMENT, EVOASM_ERROR_CODE_NONE, NULL,
           "example type mismatch (%d != %d)", input->types[i], program->_input.types[i]);
      return false;
    }
  }

  program->output_vals = alloca(EVOASM_PROGRAM_OUTPUT_VALS_SIZE(input));
  signal_ctx.exception_mask = program->exception_mask;
  program->_signal_ctx = &signal_ctx;

  if(!evoasm_program_emit(program, input, false, false, true)) {
    return false;
  }

  // FIXME:
  if(kernel->n_output_regs == 0) {
    return true;
  }

  evoasm_buf_log(program->buf, EVOASM_LOG_LEVEL_DEBUG);
  evoasm_signal_context_install(&signal_ctx, program->arch);

  if(!evoasm_buf_protect(program->buf, EVOASM_MPROT_RX)) {
    evoasm_assert_not_reached();
  }

  if(_EVOASM_SIGNAL_CONTEXT_TRY(&signal_ctx)) {
    evoasm_buf_exec(program->buf);
    evoasm_program_load_output(program,
                               kernel,
                               input,
                               &program->_output,
                               program->_matching,
                               output);
    retval = true;
  } else {
    evoasm_debug("signaled\n");
    retval = false;
  }

  if(!evoasm_buf_protect(program->buf, EVOASM_MPROT_RW)) {
    evoasm_assert_not_reached();
  }

  evoasm_signal_context_uninstall(&signal_ctx);

  program->_signal_ctx = NULL;
  program->output_vals = NULL;

  return retval;
}

static evoasm_success
evoasm_search_eval_program(evoasm_search *search,
                          evoasm_program *program,
                          evoasm_fitness *fitness) {

  evoasm_kernel *kernel = &program->kernels[program->params->size - 1];

  if(!evoasm_program_emit(program, &search->params.program_input, true, true, true)) {
    *fitness = INFINITY;
    return false;
  }

  if(EVOASM_UNLIKELY(kernel->n_output_regs == 0)) {
    *fitness = INFINITY;
    return true;
  }

  //evoasm_buf_log(program->buf, EVOASM_LOG_LEVEL_INFO);
  {
    struct evoasm_signal_context *signal_ctx = (struct evoasm_signal_context *) program->_signal_ctx;
    signal_ctx->exception_mask = program->exception_mask;

    if(_EVOASM_SIGNAL_CONTEXT_TRY((struct evoasm_signal_context *)program->_signal_ctx)) {
      evoasm_buf_exec(program->buf);
      *fitness = evoasm_program_assess(program, &search->params.program_output, search->pop.matching);
    } else {
      evoasm_debug("program %d signaled", program->index);
      *fitness = INFINITY;
    }
  }
  return true;
}

#if 0
static bool
evoasm_kernel_param_x64_writes_p(evoasm_kernel_param *param, evoasm_output_reg *reg) {
  evoasm_x64_inst *x64_inst = (evoasm_x64_inst *) param->inst;
  unsigned i;

  for(i = 0; i < x64_inst->n_operands; i++) {
    evoasm_x64_operand *op = &x64_inst->operands[i];
    evoasm_x64_reg_id reg_id = evoasm_op_x64_reg_id(op, param);

    if(op->acc_w && reg_id == reg->id) {
      return true;
    }
  }
  return false;
}

static bool
evoasm_kernel_param_writes_p(evoasm_kernel_param *param, evoasm_output_reg *reg, evoasm_arch_id arch_id) {
  switch(arch_id) {
    case EVOASM_ARCH_X64: {
      return evoasm_kernel_param_x64_writes_p(param, reg);
    }
    default:
      evoasm_assert_not_reached();
      return false;
  }
}

static int
evoasm_program_find_writer(evoasm_program *program, evoasm_kernel *kernel, evoasm_output_reg *reg, unsigned index) {
  int i;
  for(i = (int) index; i >= 0; i--) {
    evoasm_kernel_param *param = &kernel->params->params[i];

    if(evoasm_kernel_param_writes_p(param, reg, program->arch->cls->id)) {
      return i;
    }
  }
  return -1;
}

static void
evoasm_program_mark(evoasm_program *program, evoasm_reg_id reg_id, evoasm_bitmap *marked, unsigned index);

static void
evoasm_program_x64_mark_kernel(evoasm_program *program, evoasm_kernel *kernel, evoasm_bitmap *marked, unsigned writer_idx) {
  unsigned i;
  evoasm_kernel_param *param = &kernel->params->params[writer_idx];
  evoasm_x64_inst *x64_inst = (evoasm_x64_inst *) param->inst;

  for(i = 0; i < x64_inst->n_operands; i++) {
    evoasm_x64_operand *op = &x64_inst->operands[i];
    evoasm_x64_reg_id reg_id = evoasm_op_x64_reg_id(op, param);

    if(op->acc_r && writer_idx > 0) {
      evoasm_program_mark(program, reg_id, marked, writer_idx - 1);
    }
  }
}

static void
evoasm_program_mark_kernel(evoasm_program *program, evoasm_kernel *kernel, evoasm_output_reg reg, evoasm_bitmap *marked, unsigned index) {
  int writer_idx = evoasm_program_find_writer(program, kernel, &reg, index);
  if(writer_idx >= 0) {
    evoasm_bitmap_set(marked, (unsigned) writer_idx);

    switch(program->arch->cls->id) {
      case EVOASM_ARCH_X64: {
        evoasm_program_x64_mark(program, marked, (unsigned) writer_idx);
        break;
      }
      default:
        evoasm_assert_not_reached();
    }
  }
}

static evoasm_success
evoasm_program_eliminate_introns_(evoasm_program *program, evoasm_kernel *kernel, evoasm_output_reg *result_regs, size_t result_regs_len) {
  evoasm_bitmap512 marked = {0};
  unsigned i, j;

  /* mark */
  for(i = 0; i < result_regs_len; i++) {
    evoasm_kernel_mark(program, result_regs[i], (evoasm_bitmap *) &marked, kernel->params->size - 1);
  }

  /* sweep */
  for(j = 0, i = 0; i < kernel->params->size; i++) {
    if(evoasm_bitmap_get((evoasm_bitmap *) &marked, i)) {
      kernel->params->params[j++] = kernel->params->params[i];
    }
  }
  program->params->size = (evoasm_program_size) j;
     

  return true;
}

evoasm_success
evoasm_program_eliminate_introns(evoasm_program *program) {
  evoasm_bitmap512 marked = {0};
  unsigned i, j;
  evoasm_output_reg *result_regs = alloca(program->_output.arity * sizeof(evoasm_output_reg));
  evoasm_kernel *last_kernel = &program->kernels[program->params->size - 1];
  size_t input_mapping_size = 2 * EVOASM_KERNEL_MAX_INPUT_REGS * sizeof(uint16_t);
  uint16_t *input_mappings = alloca(program->params->size * input_mapping_size)
  uint16_t *output_mapping = alloca(program->_output.arity * 2 * sizeof(uint16_t));

  for(i = 0; i < program->params->size; i++) {
    uint16_t *input_mapping = input_mappings + i * input_mapping_size;
   
  }

  for(i = 0; i < program->_output.arity; i++) {
    result_regs[i] = last_kernel->output_regs[program->_matching[i]];
  }

  for(i = 0; i < program->params->size; i++) {
    EVOASM_TRY(error, evoasm_program_eliminate_introns_, program, &program->kernels[i], result_regs, program->_output.arity);
  }

  /*reemit, invalidates previous matching 
   * since referred indices into output_regs might have changed */
  if(!evoasm_program_emit(program, NULL, true, true, false)) {
    return false;
  }

  /* reestablish matching finding new indices */
  for(i = 0; i < program->_output.arity; i++) {
    for(j = 0; j < last_kernel->n_output_regs; j++) {
      if(last_kernel->output_regs[j].id == result_regs[i].id &&
         last_kernel->output_regs[j].size == result_regs[i].size) {
         program->_matching[i] = (uint_fast8_t) j;
        goto next;
      }
    }
    evoasm_assert_not_reached();
  next:;
  }

  return true;
error:
  return false;  
}
#endif

static evoasm_success
evoasm_search_eval_population(evoasm_search *search, unsigned char *programs,
                             evoasm_fitness min_fitness, evoasm_search_result_func result_func,
                             void *user_data) {
  unsigned i, j;
  struct evoasm_signal_context signal_ctx = {0};
  evoasm_population *pop = &search->pop;
  bool retval;
  unsigned n_examples = EVOASM_PROGRAM_INPUT_N(&search->params.program_input);

  evoasm_signal_context_install(&signal_ctx, search->arch);

  for(i = 0; i < search->params.pop_size; i++) {
    evoasm_fitness fitness;
    evoasm_program_params *program_params = _EVOASM_SEARCH_PROGRAM_PARAMS(search, programs, i);
    
    /* encode solution */
    evoasm_program program = {
      .params = program_params,
      .index = i,
      .buf = &search->pop.buf,
      .body_buf = &search->pop.body_buf,
      .arch = search->arch,
      ._signal_ctx = &signal_ctx
    };

    program.output_vals = pop->output_vals;

    for(j = 0; j < program_params->size; j++) {
      evoasm_kernel *kernel = &program.kernels[j];
      kernel->params = _EVOASM_PROGRAM_PARAMS_KERNEL_PARAMS(program_params, search->params.max_kernel_size, j);
      kernel->idx = (evoasm_program_size) j;
    }

    if(!evoasm_search_eval_program(search, &program, &fitness)) {
      retval = false;
      goto done;
    }

    pop->fitnesses[i] = fitness;

    evoasm_debug("program %d has fitness %lf", i, fitness);

    if(fitness <= pop->best_fitness) {
      pop->elite[pop->elite_pos++ % EVOASM_SEARCH_ELITE_SIZE] = i;
      pop->best_fitness = fitness;
      evoasm_debug("program %d has best fitness %lf", i, fitness);
    }

    if(EVOASM_UNLIKELY(fitness / n_examples <= min_fitness)) {
      evoasm_info("program %d has best fitness %lf", i, fitness);
      program._output = search->params.program_output;
      program._input = search->params.program_input;
      program._matching = search->pop.matching;

      if(!result_func(&program, fitness, user_data)) {
        retval = false;
        goto done;
      }
    }
  }

  retval = true;
done:
  evoasm_signal_context_uninstall(&signal_ctx);
  return retval;
}

static void
evoasm_search_select_parents(evoasm_search *search, uint32_t *parents) {
  uint32_t n = 0;
  unsigned i, j, k;

  /* find out degree elite array is really filled */
  for(i = 0; i < EVOASM_SEARCH_ELITE_SIZE; i++) {
    if(search->pop.elite[i] == UINT32_MAX) {
      break;
    }
  }

  /* fill possible free slots */
  for(j = i, k = 0; j < EVOASM_SEARCH_ELITE_SIZE; j++) {
    search->pop.elite[j] = search->pop.elite[k++ % i];
  }

  j = 0;
  while(true) {
    for(i = 0; i < search->params.pop_size; i++) {
      uint32_t r = evoasm_prng32_rand(&search->pop.prng32);
      if(n >= search->params.pop_size) goto done;
      if(r < UINT32_MAX * ((search->pop.best_fitness + 1.0) / (search->pop.fitnesses[i] + 1.0))) {
        parents[n++] = i;
        //evoasm_info("selecting fitness %f", search->pop.fitnesses[i]);
      } else if(r < UINT32_MAX / 32) {
        parents[n++] = search->pop.elite[j++ % EVOASM_SEARCH_ELITE_SIZE];
        //evoasm_info("selecting elite fitness %f", search->pop.fitnesses[parents[n - 1]]);
      } else {
        //evoasm_info("discarding fitness %f", search->pop.fitnesses[i]);
      }
    }
  }
done:;
}

static void
evoasm_search_mutate_kernel(evoasm_search *search, evoasm_kernel_params *child) {
  uint32_t r = evoasm_prng32_rand(&search->pop.prng32);
  evoasm_debug("mutating child: %u < %u", r, search->params.mutation_rate);
  if(r < search->params.mutation_rate) {

    r = evoasm_prng32_rand(&search->pop.prng32);
    if(child->size > search->params.min_kernel_size && r < UINT32_MAX / 16) {
      uint32_t index = r % child->size;

      if(index < (uint32_t) (child->size - 1)) {
        memmove(child->params + index, child->params + index + 1, (child->size - index - 1) * sizeof(evoasm_kernel_param));
      }
      child->size--;
    }

    r = evoasm_prng32_rand(&search->pop.prng32);
    {
      evoasm_kernel_param *program_param = child->params + (r % child->size);
      evoasm_search_seed_kernel_param(search, program_param);
    }
  }
}

static void
evoasm_search_crossover_kernel(evoasm_search *search, evoasm_kernel_params *parent_a, evoasm_kernel_params *parent_b,
                               evoasm_kernel_params *child) {
                                 
    /* NOTE: parent_a must be the longer parent, i.e. parent_size_a >= parent_size_b */
    evoasm_kernel_size child_size;
    unsigned crossover_point, crossover_len, i;

    assert(parent_a->size >= parent_b->size);

    child_size = (evoasm_kernel_size)
      evoasm_prng32_rand_between(&search->pop.prng32,
        parent_b->size, parent_a->size);

    assert(child_size > 0);
    assert(child_size >= parent_b->size);

    /* offset for shorter parent */
    crossover_point = (unsigned) evoasm_prng32_rand_between(&search->pop.prng32,
        0, child_size - parent_b->size);
    crossover_len = (unsigned) evoasm_prng32_rand_between(&search->pop.prng32,
        0, parent_b->size);


    for(i = 0; i < child_size; i++) {
      unsigned index;
      evoasm_kernel_params *parent;

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

    evoasm_search_mutate_kernel(search, child);
}


static void
evoasm_search_crossover_program(evoasm_search *search, evoasm_program_params *parent_a, evoasm_program_params *parent_b,
                                evoasm_program_params *child) {

  /* NOTE: parent_a must be the longer parent, i.e. parent_size_a >= parent_size_b */
  evoasm_program_size child_size;
  unsigned i, max_kernel_size;
  
  
  assert(parent_a->size >= parent_b->size);
  assert(parent_a->size > 0);
  assert(parent_b->size > 0);

  child_size = (evoasm_program_size)
    evoasm_prng32_rand_between(&search->pop.prng32,
      parent_b->size, parent_a->size);

  assert(child_size > 0);
  assert(child_size >= parent_b->size);

  max_kernel_size = search->params.max_kernel_size;

  for(i = 0; i < child_size; i++) {
    evoasm_kernel_params *kernel_child = _EVOASM_PROGRAM_PARAMS_KERNEL_PARAMS(child, max_kernel_size, i);

    if(i < parent_b->size) {
      evoasm_kernel_params *kernel_parent_a = _EVOASM_PROGRAM_PARAMS_KERNEL_PARAMS(parent_a, max_kernel_size, i);
      evoasm_kernel_params *kernel_parent_b = _EVOASM_PROGRAM_PARAMS_KERNEL_PARAMS(parent_b, max_kernel_size, i);
      
      if(kernel_parent_a->size < kernel_parent_b->size) {
        evoasm_kernel_params *t = kernel_parent_a;
        kernel_parent_a = kernel_parent_b;
        kernel_parent_b = t;
      }
      
      evoasm_search_crossover_kernel(search, kernel_parent_a, kernel_parent_b, kernel_child);
    } else {
      memcpy(kernel_child, parent_a, _EVOASM_KERNEL_SIZE(max_kernel_size));
      evoasm_search_mutate_kernel(search, kernel_child);
    }
  }
  child->size = child_size;
}

static void
evoasm_search_crossover(evoasm_search *search, evoasm_program_params *parent_a, evoasm_program_params *parent_b,
                        evoasm_program_params *child_a, evoasm_program_params *child_b) {

  if(parent_a->size < parent_b->size) {
    evoasm_program_params *t = parent_a;
    parent_a = parent_b;
    parent_b = t;
  }

  //memcpy(_EVOASM_SEARCH_PROGRAM_PARAMS(search, programs, index), parent_a, _EVOASM_PROGRAM_SIZE(search));
  //memcpy(_EVOASM_SEARCH_PROGRAM_PARAMS(search, programs, index + 1), parent_a, _EVOASM_PROGRAM_SIZE(search));

  evoasm_search_crossover_program(search, parent_a, parent_b, child_a);
  if(child_b != NULL) {
    evoasm_search_crossover_program(search, parent_a, parent_b, child_b);
  }
}

static void
evoasm_search_combine_parents(evoasm_search *search, unsigned char *programs, uint32_t *parents) {
  unsigned i;

  for(i = 0; i < search->params.pop_size; i += 2) {
    evoasm_program_params *parent_a = _EVOASM_SEARCH_PROGRAM_PARAMS(search, programs, parents[i]);
    assert(parent_a->size > 0);
    evoasm_program_params *parent_b = _EVOASM_SEARCH_PROGRAM_PARAMS(search, programs, parents[i + 1]);
    evoasm_program_params *child_a = _EVOASM_SEARCH_PROGRAM_PARAMS(search, search->pop.programs_swap, i);
    evoasm_program_params *child_b = _EVOASM_SEARCH_PROGRAM_PARAMS(search, search->pop.programs_swap, i + 1);
    evoasm_search_crossover(search, parent_a, parent_b, child_a, child_b);
    
    assert(child_a->size > 0);
    assert(child_b->size > 0);
  }
}

static void
evoasm_population_swap(evoasm_population *pop, unsigned char **programs) {
  unsigned char *programs_tmp;

  programs_tmp = pop->programs_swap;
  pop->programs_swap = *programs;
  *programs = programs_tmp;
}

static evoasm_fitness
evoasm_search_population_fitness(evoasm_search *search, unsigned *n_inf) {
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
evoasm_search_new_generation(evoasm_search *search, unsigned char **programs) {
  uint32_t *parents = alloca(search->params.pop_size * sizeof(uint32_t));
  evoasm_search_select_parents(search, parents);

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

    evoasm_info("population selected fitness: %g/%u", pop_fitness, n_inf);
  }

  unsigned i;
  for(i = 0; i < search->params.pop_size; i++) {
    evoasm_program_params *program_params = _EVOASM_SEARCH_PROGRAM_PARAMS(search, search->pop.programs, parents[i]);
    assert(program_params->size > 0);
  }
#endif

  evoasm_search_combine_parents(search, *programs, parents);
  evoasm_population_swap(&search->pop, programs);
}

#define EVOASM_SEARCH_CONVERGENCE_THRESHOLD 0.03

static evoasm_success
evoasm_search_start_(evoasm_search *search, unsigned char **programs,
                    evoasm_fitness min_fitness, evoasm_search_result_func result_func,
                    void *user_data) {
  unsigned gen;
  evoasm_fitness last_fitness = 0.0;
  unsigned ups = 0;

  for(gen = 0;;gen++) {
    if(!evoasm_search_eval_population(search, *programs, min_fitness, result_func, user_data)) {
      return true;
    }

    if(gen % 256 == 0) {
      unsigned n_inf;
      evoasm_fitness fitness = evoasm_search_population_fitness(search, &n_inf);
      evoasm_info("population fitness: %g/%u\n\n", fitness, n_inf);

      if(gen > 0) {
        if(last_fitness <= fitness) {
          ups++;
        }
      }

      last_fitness = fitness;

      if(ups >= 3) {
        evoasm_info("reached convergence\n");
        return false;
      }
    }

    evoasm_search_new_generation(search, programs);
  }
}

static void
evoasm_search_merge(evoasm_search *search) {
  unsigned i;

  evoasm_info("merging\n");

  for(i = 0; i < search->params.pop_size; i++) {
    evoasm_program_params *parent_a = _EVOASM_SEARCH_PROGRAM_PARAMS(search, search->pop.programs_main, i);
    evoasm_program_params *parent_b = _EVOASM_SEARCH_PROGRAM_PARAMS(search, search->pop.programs_aux, i);

    evoasm_program_params *child = _EVOASM_SEARCH_PROGRAM_PARAMS(search, search->pop.programs_swap, i);
    evoasm_search_crossover(search, parent_a, parent_b, child, NULL);
  }
  evoasm_population_swap(&search->pop, &search->pop.programs_main);
}

void
evoasm_search_start(evoasm_search *search, evoasm_fitness min_fitness, evoasm_search_result_func result_func, void *user_data) {

  unsigned kalpa;

  evoasm_search_seed(search, search->pop.programs_main);

  for(kalpa = 0;;kalpa++) {
    if(!evoasm_search_start_(search, &search->pop.programs_main, min_fitness, result_func, user_data)) {
      evoasm_search_seed(search, search->pop.programs_aux);
      evoasm_info("starting aux search");
      if(!evoasm_search_start_(search, &search->pop.programs_aux, min_fitness, result_func, user_data)) {
        evoasm_search_merge(search);
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

evoasm_success
evoasm_search_init(evoasm_search *search, evoasm_arch *arch, evoasm_search_params *search_params) {
  unsigned i, j, k;
  evoasm_domain cloned_domain;
  evoasm_arch_params_bitmap active_params = {0};

  if(search_params->max_program_size > EVOASM_PROGRAM_MAX_SIZE) {
    evoasm_set_error(EVOASM_ERROR_TYPE_ARGUMENT, EVOASM_ERROR_CODE_NONE,
      NULL, "Program size cannot exceed %d", EVOASM_PROGRAM_MAX_SIZE);
  }

  search->params = *search_params;
  search->arch = arch;

  EVOASM_TRY(fail, evoasm_population_init, &search->pop, search);

  for(i = 0; i < search_params->params_len; i++) {
    evoasm_bitmap_set((evoasm_bitmap *) &active_params, search_params->params[i]);
  }

  search->domains = evoasm_calloc((size_t)(search->params.insts_len * search->params.params_len),
      sizeof(evoasm_domain));

  for(i = 0; i < search->params.insts_len; i++) {
    evoasm_inst *inst = search->params.insts[i];
    for(j = 0; j < search->params.params_len; j++) {
      evoasm_domain *inst_domain = &search->domains[i * search->params.params_len + j];
      evoasm_arch_param_id param_id =search->params.params[j];
      for(k = 0; k < inst->params_len; k++) {
        evoasm_arch_param *param = &inst->params[k];
        if(param->id == param_id) {
          evoasm_domain *user_domain = search->params.domains[param_id];
          if(user_domain != NULL) {
            evoasm_domain_clone(user_domain, &cloned_domain);
            evoasm_domain_intersect(&cloned_domain, param->domain, inst_domain);
          } else {
            evoasm_domain_clone(param->domain, inst_domain);
          }
          goto found;
        }
      }
      /* not found */
      inst_domain->type = EVOASM_N_DOMAIN_TYPES;
found:;
    }
  }

  assert(search->params.min_program_size > 0);
  assert(search->params.min_program_size <= search->params.max_program_size);

  return true;
fail:
  return false;
}

evoasm_success
evoasm_search_destroy(evoasm_search *search) {
  unsigned i;

  for(i = 0; i < EVOASM_ARCH_MAX_PARAMS; i++) {
    evoasm_free(search->params.domains[i]);
  }
  evoasm_free(search->params.program_input.vals);
  evoasm_free(search->params.program_output.vals);
  evoasm_free(search->params.params);
  evoasm_free(search->domains);
  EVOASM_TRY(error, evoasm_population_destroy, &search->pop);

  return true;
error:
  return false;
}
