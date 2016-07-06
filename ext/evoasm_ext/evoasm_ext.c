#include <ruby.h>

static VALUE mEvoasm;
static VALUE cX64;
VALUE evoasm_cX64Instruction;
static VALUE cInstruction;
static VALUE cParameters;
static VALUE cX64Parameters;
static VALUE cParameter;
static VALUE cRegister;
static VALUE cX64Register;
static VALUE cOperand;
static VALUE cX64Operand;
static VALUE cArchitecture;
static VALUE cBuffer;
static VALUE cSearch;
static VALUE cProgram;
static VALUE cKernel;
static VALUE eError;
static VALUE eArchitectureError;

static VALUE domains_cache;
static VALUE instructions_cache;

static ID rb_id_brute_force;
static ID rb_id_genetic;
static ID rb_id_id;

#include "evoasm-x64.h"
#include "evoasm-buf.h"
#include "evoasm-search.h"

void evoasm_raise_last_error();

static void
buf_free(void *p) {
  evoasm_buf *buf = (evoasm_buf *)p;
  EVOASM_TRY(raise, evoasm_buf_destroy, buf);
  xfree(p);
  return;

raise:
  xfree(p);
  evoasm_raise_last_error();
}

static const rb_data_type_t rb_buf_type = {
  "Evoasm::Buffer",
  {NULL, buf_free, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static void
x64_free(void *p) {
  evoasm_x64 *x64 = (evoasm_x64 *) p;
  evoasm_x64_destroy(x64);
  xfree(p);
}

static void
x64_mark(void *p) {
  evoasm_x64 *x64 = (evoasm_x64 *) p;
  (void) x64;
}

static const rb_data_type_t rb_arch_type = {
  "Evoasm::Architecture",
  {NULL, NULL, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_x64_type = {
  "Evoasm::X64",
  {x64_mark, x64_free, NULL,},
  &rb_arch_type, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE
rb_buffer_alloc(VALUE klass) {
  evoasm_buf *buf = ALLOC(evoasm_buf);

  return TypedData_Wrap_Struct(klass, &rb_buf_type, buf);
}

static VALUE
rb_buffer_initialize(int argc, VALUE *argv, VALUE self) {
  evoasm_buf *buf;
  VALUE rb_size;
  VALUE rb_malloc = Qtrue;

  TypedData_Get_Struct(self, evoasm_buf, &rb_buf_type, buf);

  rb_scan_args(argc, argv, "11", &rb_size, &rb_malloc);

  EVOASM_TRY(failed, evoasm_buf_init, buf,
      RTEST(rb_malloc) ? EVOASM_BUF_TYPE_MALLOC : EVOASM_BUF_TYPE_MMAP, NUM2SIZET(rb_size));

  return self;

failed:
  return Qnil;
}

#ifdef HAVE_CAPSTONE_CAPSTONE_H
#include <capstone/capstone.h>

static VALUE
x64_disassemble(unsigned char *data, size_t len, bool addr) {
  csh handle;
  cs_insn *insn;
  size_t count;
  VALUE rb_result;

  /* FIXME: check arch */
  if(cs_open(CS_ARCH_X86, CS_MODE_64, &handle) != CS_ERR_OK) {
    return Qnil;
  }

  count = cs_disasm(handle, data, len, (uintptr_t) data, 0, &insn);
  rb_result = rb_ary_new2((long) count);
  if(count > 0) {
    size_t j;

    for(j = 0; j < count; j++) {
      VALUE line;
      if(addr) {
        line = rb_sprintf("0x%"PRIx64":  %s   %s", insn[j].address, insn[j].mnemonic, insn[j].op_str);
      } else {
        line = rb_sprintf("%s %s", insn[j].mnemonic, insn[j].op_str);
      }
      rb_ary_push(rb_result, line);
    }
    cs_free(insn, count);
  }

  cs_close(&handle);
  return rb_result;
}

static VALUE
rb_buffer_disassemble(VALUE self) {
  evoasm_buf *buf;
  TypedData_Get_Struct(self, evoasm_buf, &rb_buf_type, buf);

  return x64_disassemble(buf->data, buf->pos, true);
}

static VALUE
rb_x64_s_disassemble(VALUE self, VALUE as_str) {
  unsigned char *data = (unsigned char *) RSTRING_PTR(as_str);
  size_t len = (size_t)RSTRING_LEN(as_str);

  return x64_disassemble(data, len, false);
}
#endif

static VALUE
rb_buffer_size(VALUE self) {
  evoasm_buf *buf;
  TypedData_Get_Struct(self, evoasm_buf, &rb_buf_type, buf);

  return SIZET2NUM(buf->capa);
}

static VALUE
rb_buffer_reset(VALUE self) {
  evoasm_buf *buf;
  TypedData_Get_Struct(self, evoasm_buf, &rb_buf_type, buf);

  evoasm_buf_reset(buf);

  return Qnil;
}

static VALUE
rb_buffer_to_s(VALUE self) {
  evoasm_buf *buf;
  TypedData_Get_Struct(self, evoasm_buf, &rb_buf_type, buf);

  return rb_usascii_str_new((char *)buf->data, (long) buf->pos);
}

#if 0
static VALUE
rb_buffer_protect(VALUE self, evoasm_buf_prot mode) {
  evoasm_buf *buf;

  TypedData_Get_Struct(self, evoasm_buf, &rb_buf_type, buf);
  return evoasm_buf_protect(buf, mode) ? Qtrue : Qfalse;
}

static VALUE
rb_buffer_rx(VALUE self) {
  return rb_buffer_protect(self, EVOASM_BUF_PROT_RX);
}

static VALUE
rb_buffer_rw(VALUE self) {
  return rb_buffer_protect(self, EVOASM_BUF_PROT_RW);
}
#endif


//evoasm_inst *evoasm_population_inst_seed_random(uint32_t sol_idx, uint32_t inst_idx, void *insts, uint16_t, void *) {
//  return NULL
//}

static void
search_free(void *p) {
  evoasm_search *search = (evoasm_search *)p;
  evoasm_search_destroy(search);
  xfree(p);
}

static void
search_mark(void *p) {
  //evoasm_search *search = (evoasm_search *)p;
}

static const rb_data_type_t rb_search_type = {
  "Evoasm::Search",
  {search_mark, search_free, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE
rb_search_alloc(VALUE klass) {
  evoasm_search *search = ZALLOC(evoasm_search);
  return TypedData_Wrap_Struct(klass, &rb_search_type, search);
}

typedef struct {
  evoasm_kernel kernel;
  VALUE params;
  VALUE insts;
  VALUE program;
} rb_evoasm_kernel;

typedef struct {
  evoasm_program program;
  //VALUE params;
  VALUE buffer;
  VALUE body_buffer;
  VALUE insts;
  VALUE arch;
  VALUE kernels;
} rb_evoasm_program;

static void
kernel_free(void *p) {
  rb_evoasm_kernel *kernel = (rb_evoasm_kernel *)p;
  xfree(kernel->kernel.params);
  xfree(p);
}

static void
program_free(void *p) {
  rb_evoasm_program *program = (rb_evoasm_program *)p;
  xfree(program->program.params);
  xfree(p);
}


static void
kernel_mark(void *p) {
  rb_evoasm_kernel *kernel = (rb_evoasm_kernel *)p;
  rb_gc_mark(kernel->params);
  rb_gc_mark(kernel->insts);
  rb_gc_mark(kernel->program);
}

static void
program_mark(void *p) {
  rb_evoasm_program *program = (rb_evoasm_program *)p;
  rb_gc_mark(program->buffer);
  rb_gc_mark(program->body_buffer);
  rb_gc_mark(program->buffer);
  rb_gc_mark(program->kernels);
}

static const rb_data_type_t rb_program_type = {
  "Evoasm::Program",
  {program_mark, program_free, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_kernel_type = {
  "Evoasm::Kernel",
  {kernel_mark, kernel_free, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_inst_type = {
  "Evoasm::Instruction",
  {NULL, NULL, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

typedef struct {
  evoasm_inst *inst;
  VALUE arch;
} rb_evoasm_inst;

typedef struct {
  evoasm_x64_inst *inst;
  VALUE arch;
} rb_evoasm_x64_inst;

static void
x64_inst_free(void *p) {
  //rb_evoasm_x64_inst *inst = (rb_evoasm_x64_inst *)p;
  xfree(p);
}

static void
x64_inst_mark(void *p) {
  rb_evoasm_x64_inst *inst = (rb_evoasm_x64_inst *)p;
  rb_gc_mark(inst->arch);
}

static const rb_data_type_t rb_x64_inst_type = {
  "Evoasm::X64::Instruction",
  {x64_inst_mark, x64_inst_free, NULL,},
  &rb_inst_type, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE
rb_program_buffer(int argc, VALUE *argv, VALUE self) {
  rb_evoasm_program *program;
  VALUE buffer;
  VALUE rb_sandbox = Qfalse;

  rb_scan_args(argc, argv, "01", &rb_sandbox);

  TypedData_Get_Struct(self, rb_evoasm_program, &rb_program_type, program);

  if(RTEST(rb_sandbox)) {
    buffer = program->buffer;
  } else {
    buffer = program->body_buffer;
  }

  return buffer;
}

static VALUE
rb_program_kernels(VALUE self) {
  rb_evoasm_program *program;
  TypedData_Get_Struct(self, rb_evoasm_program, &rb_program_type, program);

  return program->kernels;
}

static void
rb_examples_to_c(VALUE rb_examples, VALUE rb_arity, evoasm_program_io *examples) {
  unsigned i;
  long examples_len;

  Check_Type(rb_examples, T_ARRAY);

  examples_len = RARRAY_LEN(rb_examples);
  if(examples_len == 0) {
    rb_raise(rb_eArgError, "examples must not be empty");
    return;
  }

  examples->vals = evoasm_calloc((size_t) examples_len, sizeof(evoasm_example_val));
  examples->len = (uint16_t) examples_len;
  examples->arity = (uint8_t) NUM2CHR(rb_arity);

  for(i = 0; i < EVOASM_PROGRAM_IO_MAX_ARITY; i++) {
    examples->types[i] = EVOASM_EXAMPLE_TYPE_I64;
  }

  for(i = 0; i < examples->len; i++) {
    VALUE elem = RARRAY_AREF(rb_examples, i);
    if(RB_FLOAT_TYPE_P(elem)) {
      examples->types[i % examples->arity] = EVOASM_EXAMPLE_TYPE_F64;
    }
  }

  for(i = 0; i < examples->len; i++) {
    VALUE elem = RARRAY_AREF(rb_examples, i);
    switch(examples->types[i % examples->arity]) {
      case EVOASM_EXAMPLE_TYPE_F64:
        examples->vals[i].f64 = NUM2DBL(elem);
        break;
      case EVOASM_EXAMPLE_TYPE_I64:
        examples->vals[i].i64 = NUM2LL(elem);
        break;
      default:
        evoasm_assert_not_reached();
    }
  }
}

static VALUE
example_val_to_rb(evoasm_example_val val, evoasm_example_type type) {
  switch(type) {
    case EVOASM_EXAMPLE_TYPE_U64: return ULL2NUM(val.u64);
    case EVOASM_EXAMPLE_TYPE_I64: return LL2NUM(val.i64);
    case EVOASM_EXAMPLE_TYPE_F64: return rb_float_new((double) val.f64);
    default:
      evoasm_assert_not_reached();
      return Qnil;
  }
}

static VALUE
rb_program_eliminate_introns_bang(VALUE self) {
  rb_evoasm_program *program;

  TypedData_Get_Struct(self, rb_evoasm_program, &rb_program_type, program);

  EVOASM_TRY(raise, evoasm_program_eliminate_introns, &program->program);

  return self;
raise:
    evoasm_raise_last_error();
    return Qnil;
}

static VALUE
rb_program_output_registers(VALUE self) {
  rb_evoasm_program *program;
  VALUE ary = rb_ary_new();
  size_t i;
  
  TypedData_Get_Struct(self, rb_evoasm_program, &rb_program_type, program);

  for(i = 0; i < program->program._output.arity; i++) {
    switch(program->program.arch->cls->id) {
        case EVOASM_ARCH_X64:
          rb_ary_push(ary, ID2SYM(rb_x64_reg_ids[program->program.output_regs[i]]));
          break;
        default: evoasm_assert_not_reached();
    }
  }
  return ary;
}

static VALUE
rb_program_run(VALUE self, VALUE rb_input, VALUE rb_arity) {
  rb_evoasm_program *program;
  unsigned i, j;
  VALUE rb_ary;
  evoasm_program_input input;
  evoasm_program_output output = {0};

  TypedData_Get_Struct(self, rb_evoasm_program, &rb_program_type, program);

  rb_examples_to_c(rb_input, rb_arity, &input);

  if(!evoasm_program_run(&program->program,
                        &input,
                        &output)) {
      return Qnil;
  }

  rb_ary = rb_ary_new2(EVOASM_PROGRAM_OUTPUT_N(&output));

  for(i = 0; i < EVOASM_PROGRAM_OUTPUT_N(&output); i++) {
    VALUE rb_output = rb_ary_new2(output.arity);
    for(j = 0; j < output.arity; j++) {
      VALUE val = example_val_to_rb(output.vals[i * output.arity + j],
                                    output.types[j]);
      rb_ary_push(rb_output, val);
    }
    rb_ary_push(rb_ary, rb_output);
  }
  //  rb_ary_push(rb_ary, example_val_to_rb(vals[i], examples.types[i]));
  //}

  evoasm_program_output_destroy((evoasm_program_io *) &output);

  return rb_ary;
}

static void
params_free(void *p) {
  xfree(p);
}

static const rb_data_type_t rb_params_type = {
  "Evoasm::Parameters",
  {NULL, NULL, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_x64_params_type = {
  "Evoasm::X64::Parameters",
  {NULL, params_free, NULL,},
  &rb_params_type, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE
rb_x64_parameters_alloc(VALUE klass) {
  evoasm_x64_params *x64_params = ZALLOC(evoasm_x64_params);
  return TypedData_Wrap_Struct(klass, &rb_x64_params_type, x64_params);
}

static VALUE
rb_kernel_parameters(VALUE self) {
  rb_evoasm_kernel *kernel;
  rb_evoasm_program *program;
  
  TypedData_Get_Struct(self, rb_evoasm_kernel, &rb_kernel_type, kernel);
  TypedData_Get_Struct(kernel->program, rb_evoasm_program, &rb_program_type, program);

  if(kernel->params != Qnil) return kernel->params;

  {
    unsigned i;
    kernel->params = rb_ary_new2(kernel->kernel.params->size);
    for(i = 0; i < kernel->kernel.params->size; i++) {
      VALUE rb_params;

      switch(program->program.arch->cls->id) {
        case EVOASM_ARCH_X64: {
          evoasm_x64_params *params;
          rb_params = rb_x64_parameters_alloc(cX64Parameters);
          TypedData_Get_Struct(rb_params, evoasm_x64_params, &rb_x64_params_type, params);
          MEMCPY(params->vals, kernel->kernel.params->params[i].param_vals, evoasm_arch_param_val, EVOASM_X64_N_PARAMS);
          params->set = kernel->kernel.params->params[i].set_params;
          break;
        }
        default: evoasm_assert_not_reached();
      }
      rb_ary_push(kernel->params, rb_params);
    }
  }

  return kernel->params;
}

static VALUE
rb_kernel_instructions(VALUE self) {
  rb_evoasm_kernel *kernel;
  rb_evoasm_program *program;
  
  TypedData_Get_Struct(self, rb_evoasm_kernel, &rb_kernel_type, kernel);
  TypedData_Get_Struct(kernel->program, rb_evoasm_program, &rb_program_type, program);

  if(kernel->insts != Qnil) return kernel->insts;

  {
    unsigned i;
    kernel->insts = rb_ary_new2(kernel->kernel.params->size);
    for(i = 0; i < kernel->kernel.params->size; i++) {
      VALUE rb_inst;

      switch(program->program.arch->cls->id) {
        case EVOASM_ARCH_X64: {
          rb_evoasm_x64_inst *inst = ALLOC(rb_evoasm_x64_inst);
          inst->arch = program->arch;
          inst->inst = (evoasm_x64_inst *) kernel->kernel.params->params[i].inst;
          rb_inst = TypedData_Wrap_Struct(evoasm_cX64Instruction, &rb_x64_inst_type, inst);
          break;
        }
        default: evoasm_assert_not_reached();
      }
      rb_ary_push(kernel->insts, rb_inst);
    }
  }

  return kernel->insts;
}

static VALUE
rb_program_alloc(VALUE klass) {
  rb_evoasm_program *program = ALLOC(rb_evoasm_program);
  //program->params = Qnil;
  program->buffer = Qnil;
  program->kernels = Qnil;
  return TypedData_Wrap_Struct(klass, &rb_program_type, program);
}

static VALUE
rb_kernel_alloc(VALUE klass) {
  rb_evoasm_kernel *kernel = ALLOC(rb_evoasm_kernel);
  kernel->params = Qnil;
  kernel->program = Qnil;
  return TypedData_Wrap_Struct(klass, &rb_kernel_type, kernel);
}


static evoasm_arch_param_id
x64_param_sym_to_id(VALUE sym) {
  int i;
  ID id = SYM2ID(sym);
  for(i = 0; i < EVOASM_X64_N_PARAMS; i++) {
    if(rb_x64_param_ids[i] == id) {
      return (evoasm_x64_param_id) i;
    }
  }
  evoasm_assert_not_reached();
}

struct arch_with_params {
  evoasm_arch *arch;
  evoasm_search_params *params;
};

static evoasm_arch_param_id
param_sym_to_c(VALUE rb_key, unsigned n_params) {
  unsigned i;
  ID id = SYM2ID(rb_key);

  for(i = 0; i < n_params; i++) {
    if(rb_x64_param_ids[i] == id) {
      return (evoasm_arch_param_id) i;
    }
  }

  rb_raise(rb_eKeyError, "invalid key");
  return 0;
}

static evoasm_arch_param_val
param_val_to_c(VALUE rb_value) {
  switch(TYPE(rb_value)) {
    case T_SYMBOL: {
      unsigned i;
      ID id = SYM2ID(rb_value);
      for(i = 0; i < EVOASM_X64_N_REGS; i++) {
        if(rb_x64_reg_ids[i] == id) {
          return (evoasm_arch_param_val) i;
        }
      }
      rb_raise(rb_eArgError, "invalid value");
      break;
    }
    case T_FIXNUM:
    case T_BIGNUM:
      return NUM2LL(rb_value);
    case T_OBJECT:
      return NUM2LL(rb_funcall(rb_value, rb_id_id, 0, NULL));
    case T_TRUE:
    case T_FALSE:
      return (rb_value == Qtrue ? 1 : 0);
    default:
      rb_raise(rb_eArgError, "invalid key type");
      return 0;
  }
}

static evoasm_domain *
rb_domain_to_c(VALUE rb_domain) {
  if(rb_obj_is_kind_of(rb_domain, rb_cRange)) {
    VALUE rb_beg;
    VALUE rb_end;
    int exclp;

    evoasm_interval *interval = ALLOC(evoasm_interval);
    interval->type = EVOASM_DOMAIN_TYPE_INTERVAL;

    if(rb_range_values(rb_domain, &rb_beg, &rb_end, &exclp) == Qtrue) {
      interval->min = NUM2LL(rb_beg);
      interval->max = NUM2LL(rb_end);
      if(exclp) interval->max--;
    }
    else {
      evoasm_assert_not_reached();
    }
    return (evoasm_domain *) interval;
  } else {
    Check_Type(rb_domain, T_ARRAY);

    {
      unsigned i;
      long len = RARRAY_LEN(rb_domain);
      evoasm_enum *enm;

      if(len > EVOASM_ENUM_MAX_LEN) {
        rb_raise(rb_eArgError, "array exceeds maximum length of %d", EVOASM_ENUM_MAX_LEN);
        return NULL;
      }

      enm = xmalloc(EVOASM_ENUM_SIZE(RARRAY_LEN(rb_domain)));
      enm->type = EVOASM_DOMAIN_TYPE_ENUM;
      enm->len = (uint16_t) len;

      for(i = 0; i < RARRAY_LEN(rb_domain); i++) {
        enm->vals[i] = param_val_to_c(RARRAY_AREF(rb_domain, i));
      }
      return (evoasm_domain *) enm;
    }
  }
}

static int
set_domain(VALUE key, VALUE val, VALUE user_data) {
  struct arch_with_params *arch_with_params = (struct arch_with_params *) user_data;
  evoasm_search_params *search_params = arch_with_params->params;
  evoasm_arch_param_id param_id = param_sym_to_c(key, arch_with_params->arch->cls->n_params);
  search_params->domains[param_id] = rb_domain_to_c(val);
  return ST_CONTINUE;
}

static void
set_size_param(VALUE rb_size, evoasm_search_params *params, int id) {  
  unsigned min_size, max_size;
  
  if(FIXNUM_P(rb_size)) {
    min_size = (evoasm_program_size) FIX2UINT(rb_size);
    max_size = min_size;
  } else {
    VALUE rb_beg;
    VALUE rb_end;
    int exclp;
    if(rb_range_values(rb_size, &rb_beg, &rb_end, &exclp) == Qtrue) {
      min_size = FIX2UINT(rb_beg);
      max_size = FIX2UINT(rb_end);
      if(exclp) max_size--;
    } else {
      rb_raise(rb_eArgError, "invalid program size");
    }
  }
  
  if(id == 0) {
    params->min_kernel_size = (evoasm_kernel_size) min_size;
    params->max_kernel_size = (evoasm_kernel_size) max_size;    
  } else if(id == 1) {
    params->min_program_size = (evoasm_program_size) min_size;
    params->max_program_size = (evoasm_program_size) max_size;        
  }  else {
    evoasm_assert_not_reached();
  }
}

static VALUE
rb_search_initialize(int argc, VALUE* argv, VALUE self) {
  VALUE rb_arch, rb_pop_size, rb_kernel_size, rb_program_size, rb_insts, rb_input, rb_output;
  VALUE rb_input_arity, rb_output_arity, rb_params, rb_mutation_rate;
  VALUE rb_seed, rb_domains, rb_recur_limit;

  evoasm_search *search;
  evoasm_arch *arch;
  evoasm_search_params search_params;
  evoasm_arch_param_id *params;
  evoasm_inst **insts;
  unsigned i;
  long insts_len;
  long params_len;
  uint32_t pop_size;
  uint32_t mutation_rate;
  uint32_t recur_limit;
  
  evoasm_program_input input;
  evoasm_program_input output;

  VALUE *args[] = {
    &rb_input,
    &rb_input_arity,
    &rb_output,
    &rb_output_arity,
    &rb_arch,
    &rb_pop_size,
    &rb_kernel_size,
    &rb_program_size,    
    &rb_insts,
    &rb_params,
    &rb_mutation_rate,
    &rb_seed,
    &rb_domains,
    &rb_recur_limit
  };

  if(argc != EVOASM_ARY_LEN(args)) {
    rb_error_arity(argc, EVOASM_ARY_LEN(args), EVOASM_ARY_LEN(args));
    return Qnil;
  }

  for(i = 0; i < (unsigned) argc; i++) {
    *args[i] = argv[i];
  }

  Check_Type(rb_insts, T_ARRAY);
  Check_Type(rb_params, T_ARRAY);
  Check_Type(rb_seed, T_ARRAY);
  Check_Type(rb_domains, T_HASH);

  TypedData_Get_Struct(self, evoasm_search, &rb_search_type, search);
  TypedData_Get_Struct(rb_arch, evoasm_arch, &rb_arch_type, arch);

  insts_len = RARRAY_LEN(rb_insts);
  params_len = RARRAY_LEN(rb_params);
  pop_size = (uint32_t) FIX2UINT(rb_pop_size);
  mutation_rate = (uint32_t)(UINT32_MAX * NUM2DBL(rb_mutation_rate));
  recur_limit = (uint32_t)(FIX2UINT(rb_recur_limit));
  

  if(RARRAY_LEN(rb_seed) < 64) {
    rb_raise(rb_eArgError, "seed must be an array of size at least 64");
  }

  if(pop_size % 2) {
    rb_raise(rb_eArgError, "poulation size must be even");
    return Qnil;
  }

  if(insts_len == 0) {
    rb_raise(rb_eArgError, "instructions must not be empty");
    return Qnil;
  }

  if(params_len == 0) {
    rb_raise(rb_eArgError, "parameters must not be empty");
    return Qnil;
  }

  rb_examples_to_c(rb_input, rb_input_arity, &input);
  rb_examples_to_c(rb_output, rb_output_arity, &output);

  insts = ZALLOC_N(evoasm_inst *, (size_t) insts_len);
  for(i = 0; i < insts_len; i++) {
    VALUE elem = RARRAY_AREF(rb_insts, i);
    rb_evoasm_inst *inst;
    TypedData_Get_Struct(elem, rb_evoasm_inst, &rb_inst_type, inst);
    insts[i] = inst->inst;
  }

  params = ZALLOC_N(evoasm_arch_param_id, (size_t) params_len);
  for(i = 0; i < params_len; i++) {
    switch(arch->cls->id) {
      case EVOASM_ARCH_X64:
        params[i] = (evoasm_arch_param_id) x64_param_sym_to_id(RARRAY_AREF(rb_params, i));
        break;
      default: evoasm_assert_not_reached();
    }
  }

  search_params = (evoasm_search_params) {
    .pop_size = pop_size,
    .insts = insts,
    .program_input = input,
    .program_output = output,
    .insts_len = (uint16_t) insts_len,
    .params = params,
    .params_len = (uint8_t) params_len,
    .mutation_rate = mutation_rate,
    .recur_limit = recur_limit
  };

  for(i = 0; i < EVOASM_ARY_LEN(search_params.seed32.data); i++) {
    search_params.seed32.data[i] = (uint32_t) FIX2UINT(RARRAY_AREF(rb_seed, i));
  }

  for(i = 0; i < EVOASM_ARY_LEN(search_params.seed64.data); i++) {
    search_params.seed64.data[i] = (uint64_t) NUM2ULL(RARRAY_AREF(rb_seed, i));
  }
  
  set_size_param(rb_kernel_size, &search_params, 0);
  set_size_param(rb_program_size, &search_params, 1);

  {
    struct arch_with_params user_data = {arch, &search_params};
    rb_hash_foreach(rb_domains, set_domain, (VALUE) &user_data);
  }

  EVOASM_TRY(raise, evoasm_search_init, search, arch, &search_params);

  return self;
  
raise:
  evoasm_raise_last_error();
  return Qnil;
}

static const rb_data_type_t rb_op_type = {
  "Evoasm::Operand",
  {NULL, NULL, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_x64_op_type = {
  "Evoasm::X64::Operand",
  {NULL, NULL, NULL,},
  &rb_op_type, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_param_type = {
  "Evoasm::Parameter",
  {NULL, NULL, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_reg_type = {
  "Evoasm::Register",
  {NULL, NULL, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_x64_reg_type = {
  "Evoasm::::X64::Register",
  {NULL, NULL, NULL,},
  &rb_reg_type, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static void
x64_parameters_aset(evoasm_x64_params *params, VALUE rb_key, VALUE rb_value) {
  evoasm_arch_param_id key;
  evoasm_arch_param_val param_val = 0;

  key = param_sym_to_c(rb_key, EVOASM_X64_N_PARAMS);
  param_val = param_val_to_c(rb_value);

  evoasm_arch_params_set(params->vals, (evoasm_bitmap *) &params->set, key, param_val);
  return;
}

static VALUE
rb_x64_parameters_aset(VALUE self, VALUE rb_key, VALUE rb_value) {
  evoasm_x64_params *params;
  TypedData_Get_Struct(self, evoasm_x64_params, &rb_x64_params_type, params);

  x64_parameters_aset(params, rb_key, rb_value);
  return Qnil;
}

static VALUE
rb_x64_parameters_aref(VALUE self, VALUE rb_key) {
  evoasm_x64_params *params;
  evoasm_arch_param_id key = (evoasm_arch_param_id) FIX2UINT(rb_key);
  TypedData_Get_Struct(self, evoasm_x64_params, &rb_x64_params_type, params);

  if((unsigned)key >= (unsigned)EVOASM_X64_N_PARAMS) {
    rb_raise(rb_eKeyError, "invalid key");
    return Qnil;
  }

  if(!evoasm_bitmap_get((evoasm_bitmap *) &params->set, key)) {
    return Qnil;
  } else {
    return LL2NUM(params->vals[key]);
  }
}

static int
x64_params_set_kv(VALUE key, VALUE val, VALUE params) {
  x64_parameters_aset((evoasm_x64_params *) params, key, val);
  return ST_CONTINUE;
}

static void
x64_params_set_from_hash(evoasm_x64_params *params, VALUE hash) {
  rb_hash_foreach(hash, x64_params_set_kv, (VALUE) params);
}

static VALUE
rb_x64_parameters_initialize(int argc, VALUE *argv, VALUE self) {
  evoasm_x64_params *params;
  VALUE rb_params;

  TypedData_Get_Struct(self, evoasm_x64_params, &rb_x64_params_type, params);
  rb_scan_args(argc, argv, "01", &rb_params);

  if(!NIL_P(rb_params)) {
    x64_params_set_from_hash(params, rb_params);
  }

  return self;
}

static void
error_free(void *p) {
  evoasm_error *error = (evoasm_error *)p;
  (void) error;
  xfree(p);
}

void *realloc_func(void *ptr, size_t size) {
  return ruby_xrealloc(ptr, size);
}


static ID error_code_unknown;
static ID error_code_not_encodable;
static ID error_code_missing_param;
static ID error_code_invalid_access;
static ID error_code_missing_feature;

struct result_func_data {
  evoasm_program *program;
  evoasm_loss loss;
  evoasm_search *search;
  int tag;
  VALUE block;
};

static VALUE
result_func(VALUE user_data) {

  struct result_func_data *data = (struct result_func_data *) user_data;

  evoasm_loss loss = data->loss;
  evoasm_program tmp_program = *data->program;

  /*VALUE proc = (VALUE) user_data;*/
  VALUE rb_program = rb_program_alloc(cProgram);
  VALUE rb_buffer = rb_buffer_alloc(cBuffer);
  VALUE rb_body_buffer = rb_buffer_alloc(cBuffer);
  VALUE rb_kernels = rb_ary_new2(tmp_program.params->size);

  assert(data->program->body_buf->pos > 0);

  {
    evoasm_buf *buf;
    TypedData_Get_Struct(rb_buffer, evoasm_buf, &rb_buf_type, buf);    
    EVOASM_TRY(raise, evoasm_buf_clone, data->program->buf, buf);
    tmp_program.buf = buf;
  }

  {
    evoasm_buf *buf;
    TypedData_Get_Struct(rb_body_buffer, evoasm_buf, &rb_buf_type, buf);
    EVOASM_TRY(raise, evoasm_buf_clone, data->program->body_buf, buf);
    tmp_program.body_buf = buf;
  }
  
  {
    unsigned i;
    for(i = 0; i < data->program->params->size; i++) {
      evoasm_kernel *orig_kernel = &data->program->kernels[i];
      rb_evoasm_kernel *kernel;
      size_t params_size;
      
      VALUE rb_kernel = rb_kernel_alloc(cKernel);
      TypedData_Get_Struct(rb_kernel, rb_evoasm_kernel, &rb_kernel_type, kernel);

      params_size = sizeof(evoasm_kernel_params) + orig_kernel->params->size * sizeof(evoasm_kernel_param);
      kernel->kernel.params = xmalloc(params_size);
      kernel->params = Qnil;
      kernel->insts = Qnil;
      kernel->program = rb_program;
      memcpy(kernel->kernel.params, data->program->params, params_size);
      
      rb_ary_push(rb_kernels, rb_kernel);
    }
  }

  {    
    size_t params_size = sizeof(evoasm_program_params);

    tmp_program.index = 0;
    tmp_program._signal_ctx = NULL;
    tmp_program.reset_rflags = false;
    tmp_program._input.vals = NULL;
    tmp_program._output.vals = NULL;
    tmp_program.output_vals = NULL;

    tmp_program.params = xmalloc(params_size);
    memcpy(tmp_program.params, data->program->params, params_size);
  }

  {
    rb_evoasm_program *program;
    TypedData_Get_Struct(rb_program, rb_evoasm_program, &rb_program_type, program);
    
    program->kernels = rb_kernels;
    program->buffer = rb_buffer;
    program->body_buffer = rb_body_buffer;
    program->arch = (VALUE) data->program->arch->user_data;
    program->program = tmp_program;
    
    assert(program->program.body_buf->pos > 0);
  }

  {
    VALUE yield_vals[] = {rb_program, rb_float_new(loss)};
    return rb_proc_call(data->block, rb_ary_new_from_values(2, yield_vals));
  }

raise:
    evoasm_raise_last_error();
    return Qnil;
}


static bool
_result_func(evoasm_program *program, evoasm_loss loss, void *user_data) {
  struct result_func_data *result_data = (struct result_func_data *) user_data;
  VALUE retval;

  result_data->loss = loss;
  result_data->program = program;
  result_data->tag = 0;

  retval = rb_protect(result_func, (VALUE) result_data, &result_data->tag);

  if(result_data->tag != 0 || retval == Qfalse) {
    return false;
  }

  return true;
}


static VALUE
rb_search_start(VALUE self, VALUE rb_max_loss) {
  evoasm_search *search;
  VALUE block;
  struct result_func_data result_data;
  rb_need_block();

  TypedData_Get_Struct(self, evoasm_search, &rb_search_type, search);

  block = rb_block_proc();
  result_data.block = block;
  result_data.search = search;

  evoasm_search_start(search, (evoasm_loss) NUM2DBL(rb_max_loss), _result_func, &result_data);
  if(result_data.tag) {
    rb_jump_tag(result_data.tag);
  }
  return Qnil;
}


static const rb_data_type_t rb_error_type = {
  "Evoasm::Error",
  {NULL, error_free, NULL,},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};

static const rb_data_type_t rb_arch_error_type = {
  "Evoasm::Architecture::Error",
  {NULL, error_free, NULL,},
  &rb_error_type, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY,
};


void
evoasm_raise_last_error() {
  VALUE exc;

  evoasm_error *error = &evoasm_last_error;

  switch(error->type) {
    case EVOASM_ERROR_TYPE_ARCH: {
      evoasm_arch_error *arch_error = ALLOC(evoasm_arch_error);
      *arch_error = *((evoasm_arch_error *)error);
      exc = TypedData_Wrap_Struct(eArchitectureError, &rb_arch_error_type, arch_error);
      break;
    }
    default: {
      evoasm_error *_error = ALLOC(evoasm_error);
      *_error = *error;
      exc = TypedData_Wrap_Struct(eError, &rb_error_type, _error);
      break;
    }
  }
  rb_obj_call_init(exc, 0, NULL);
  rb_exc_raise(exc);
}


static VALUE
rb_error_code(VALUE self) {
  evoasm_error *error;
  TypedData_Get_Struct(self, evoasm_error, &rb_error_type, error);

  switch(error->code) {
    case EVOASM_ERROR_CODE_NONE: return ID2SYM(error_code_unknown);
    default: return Qnil;
  }
}


static VALUE
rb_error_message(VALUE self) {
  evoasm_error *error;
  size_t len;
  TypedData_Get_Struct(self, evoasm_error, &rb_error_type, error);

  if(error->msg[0] == '\0') {
    return Qnil;
  }

  len = strnlen(error->msg, EVOASM_ERROR_MAX_MSG_LEN);
  return rb_str_new(error->msg, (long) len);
}

static VALUE
rb_architecture_error_code(VALUE self) {
  evoasm_arch_error *error;
  TypedData_Get_Struct(self, evoasm_arch_error, &rb_arch_error_type, error);

  switch(error->code) {
    case EVOASM_ARCH_ERROR_CODE_NOT_ENCODABLE: return ID2SYM(error_code_not_encodable);
    case EVOASM_ARCH_ERROR_CODE_MISSING_PARAM: return ID2SYM(error_code_missing_param);
    case EVOASM_ARCH_ERROR_CODE_INVALID_ACCESS: return ID2SYM(error_code_invalid_access);
    case EVOASM_ARCH_ERROR_CODE_MISSING_FEATURE: return ID2SYM(error_code_missing_feature);
    default: return rb_error_code(self);
  }
}

static VALUE
rb_architecture_error_parameter(VALUE self) {
  evoasm_arch_error *error;
  TypedData_Get_Struct(self, evoasm_arch_error, &rb_arch_error_type, error);

  if(error->code == EVOASM_ARCH_ERROR_CODE_MISSING_PARAM) {
    switch(error->data.arch->cls->id) {
      case EVOASM_ARCH_X64: return ID2SYM(rb_x64_param_ids[error->data.param]);
      default: evoasm_assert_not_reached();
    }
  }
  else {
    return Qnil;
  }
}

static VALUE
rb_architecture_error_register(VALUE self) {
  evoasm_arch_error *error;
  TypedData_Get_Struct(self, evoasm_arch_error, &rb_arch_error_type, error);

  if(error->code == EVOASM_ARCH_ERROR_CODE_INVALID_ACCESS) {
    switch(error->data.arch->cls->id) {
      case EVOASM_ARCH_X64: return ID2SYM(rb_x64_reg_ids[error->data.reg]);
      default: evoasm_assert_not_reached();
    }
  }
  else {
    return Qnil;
  }
}

static VALUE
rb_architecture_error_instruction(VALUE self) {
  evoasm_arch_error *error;
  TypedData_Get_Struct(self, evoasm_arch_error, &rb_arch_error_type, error);

  if(error->code == EVOASM_ARCH_ERROR_CODE_INVALID_ACCESS) {
    switch(error->data.arch->cls->id) {
      case EVOASM_ARCH_X64: return ID2SYM(rb_x64_inst_ids[error->data.inst]);
      default: evoasm_assert_not_reached();
    }
  }
  else {
    return Qnil;
  }
}

static VALUE
rb_architecture_error_architecture(VALUE self) {
  evoasm_arch_error *error;
  TypedData_Get_Struct(self, evoasm_arch_error, &rb_arch_error_type, error);

  if(error->data.arch->user_data != NULL) {
    return (VALUE) error->data.arch->user_data;
  }
  else {
    evoasm_assert_not_reached();
  }
}

static VALUE
rb_x64_alloc(VALUE klass) {
  evoasm_x64 *x64 = xmalloc(sizeof(evoasm_x64));

  return TypedData_Wrap_Struct(klass, &rb_x64_type, x64);
}

static VALUE
rb_x64_initialize(VALUE self) {
  evoasm_x64 *x64;
  TypedData_Get_Struct(self, evoasm_x64, &rb_x64_type, x64);

  EVOASM_TRY(raise, evoasm_x64_init, x64);
  ((evoasm_arch *)x64)->user_data = (void *) self;

  return self;

raise:
  evoasm_raise_last_error();
  return Qnil;
}

static VALUE
x64_instruction_encode(evoasm_x64_inst *inst, evoasm_x64 *x64, VALUE rb_params) {
  evoasm_x64_params *params;
  evoasm_x64_params _params = {0};
  evoasm_arch *arch = (evoasm_arch *) x64;
  VALUE rb_str;

  switch(TYPE(rb_params)) {
    case T_DATA:
      TypedData_Get_Struct(rb_params, evoasm_x64_params, &rb_x64_params_type, params);
      break;
    case T_HASH:
      x64_params_set_from_hash(&_params, rb_params);
      params = &_params;
      break;
    default:
      rb_raise(rb_eArgError, "parameters must be hash or Evoasm::X64::Parameters");
      return Qnil;
  }

  EVOASM_TRY(raise, evoasm_inst_encode, (evoasm_inst *)inst, arch, params->vals, (evoasm_bitmap *) &params->set);

  rb_str = rb_usascii_str_new((char *)(arch->buf + arch->buf_start),
                            (long) (arch->buf_end - arch->buf_start));
  evoasm_arch_reset(arch);
  return rb_str;

raise:
  evoasm_raise_last_error();
  return Qnil;

}

static VALUE
rb_x64_encode(int argc, VALUE *argv, VALUE self) {
  evoasm_x64 *x64;
  unsigned i;
  ID id;
  VALUE rb_params;
  VALUE rb_inst_name;
  evoasm_x64_inst *inst = NULL;

  rb_scan_args(argc, argv, "2", &rb_inst_name, &rb_params);

  Check_Type(rb_inst_name, T_SYMBOL);
  Check_Type(rb_params, T_HASH);
  id = SYM2ID(rb_inst_name);

  TypedData_Get_Struct(self, evoasm_x64, &rb_x64_type, x64);

  for(i = 0; i < EVOASM_X64_N_INSTS; i++) {
    if(rb_x64_inst_ids[i] == id) {
      inst = (evoasm_x64_inst *) evoasm_x64_get_inst(x64, i, true);
      break;
    }
  }

  if(inst == NULL) {
    rb_raise(rb_eArgError, "unknown instruction");
    return Qnil;
  }

  return x64_instruction_encode(inst, x64, rb_params);
}

static VALUE
rb_x64_register_id(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_reg_type, op);
  return UINT2NUM(op->reg_id);
}

static VALUE
rb_x64_register_name(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_reg_type, op);
  if(op->reg_id < EVOASM_X64_N_REGS) {
    return ID2SYM(rb_x64_reg_ids[op->reg_id]);
  }
  else {
    return Qnil;
  }
}

static VALUE
rb_x64_register_type(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_reg_type, op);
  return ID2SYM(rb_x64_reg_type_ids[op->reg_type]);
}

static VALUE
rb_x64_operand_type(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_op_type, op);

  return ID2SYM(rb_x64_operand_type_ids[op->type]);
}

static VALUE
rb_x64_operand_written_p(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_op_type, op);

  return op->acc_w ? Qtrue : Qfalse;
}

static VALUE
rb_x64_operand_read_p(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_op_type, op);

  return op->acc_r ? Qtrue : Qfalse;
}

static VALUE
rb_x64_operand_register(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_op_type, op);

  if(op->type == EVOASM_X64_OPERAND_TYPE_REG ||
     op->type == EVOASM_X64_OPERAND_TYPE_RM) {
    VALUE rb_reg = TypedData_Wrap_Struct(cX64Register, &rb_x64_reg_type, op);
    return rb_reg;
  }

  return Qnil;
}

static VALUE
rb_x64_operand_size(VALUE self) {
  evoasm_x64_operand *op;
  TypedData_Get_Struct(self, evoasm_x64_operand, &rb_x64_op_type, op);

  switch(op->size) {
    case EVOASM_OPERAND_SIZE_1: return INT2FIX(1);
    case EVOASM_OPERAND_SIZE_8: return INT2FIX(8);
    case EVOASM_OPERAND_SIZE_16: return INT2FIX(16);
    case EVOASM_OPERAND_SIZE_32: return INT2FIX(32);
    case EVOASM_OPERAND_SIZE_64: return INT2FIX(64);
    case EVOASM_OPERAND_SIZE_128: return INT2FIX(128);
    case EVOASM_OPERAND_SIZE_256: return INT2FIX(256);
    case EVOASM_OPERAND_SIZE_512: return INT2FIX(512);
    default: return Qnil;
  }
  return Qnil;
}

static VALUE
rb_parameter_name(VALUE self) {
  evoasm_arch_param *param;
  TypedData_Get_Struct(self, evoasm_arch_param, &rb_param_type, param);
  return ID2SYM(rb_x64_param_ids[param->id]);
}

static VALUE
rb_parameter_id(VALUE self) {
  evoasm_arch_param *param;
  TypedData_Get_Struct(self, evoasm_arch_param, &rb_param_type, param);
  return UINT2NUM(param->id);
}

static VALUE
rb_domain_to_rb(evoasm_domain *domain) {
  VALUE rb_domain;

  switch(domain->type) {
    case EVOASM_DOMAIN_TYPE_INTERVAL: {
      evoasm_interval *interval = (evoasm_interval *) domain;
      rb_domain = rb_range_new(LL2NUM(interval->min), LL2NUM(interval->max), false);
      break;
    }
    case EVOASM_DOMAIN_TYPE_ENUM: {
      evoasm_enum *enm = (evoasm_enum *) domain;
      uint16_t j;
      VALUE *enm_vals = ALLOCA_N(VALUE, enm->len);
      for(j = 0; j < enm->len; j++) {
        enm_vals[j] = LL2NUM(enm->vals[j]);
      }
      rb_domain = rb_ary_new_from_values(enm->len, enm_vals);
      break;
    }
    default: evoasm_assert_not_reached();
  }

  return rb_domain;
}

static VALUE
rb_parameter_domain(VALUE self) {
  evoasm_arch_param *param;
  evoasm_domain *domain;
  VALUE rb_domain;

  TypedData_Get_Struct(self, evoasm_arch_param, &rb_param_type, param);

  domain = param->domain;
  rb_domain = RARRAY_AREF(domains_cache, domain->index);

  if(NIL_P(rb_domain)) {
    rb_domain = rb_domain_to_rb(domain);
    rb_obj_freeze(rb_domain);
  }
  RARRAY_ASET(domains_cache, domain->index, rb_domain);
  return rb_domain;
}


static VALUE
rb_architecture_instructions(VALUE self) {
  evoasm_arch *arch;
  evoasm_inst **insts;
  uint16_t len, i;
  VALUE *vals;

  TypedData_Get_Struct(self, evoasm_arch, &rb_arch_type, arch);
  insts = ALLOCA_N(evoasm_inst *, arch->cls->n_insts);
  len = evoasm_arch_insts(arch, (const evoasm_inst **) insts);
  if(len == 0) return Qnil;

  vals = ALLOCA_N(VALUE, len);

  for(i = 0; i < len; i++) {
    switch(arch->cls->id) {
      case EVOASM_ARCH_X64: {
        rb_evoasm_x64_inst *inst = ALLOC(rb_evoasm_x64_inst);
        inst->arch = self;
        inst->inst = (evoasm_x64_inst *) insts[i];
        vals[i] = TypedData_Wrap_Struct(evoasm_cX64Instruction, &rb_x64_inst_type, inst);
        break;
      }
      default: evoasm_assert_not_reached();
    }
  }

  return rb_ary_new_from_values(len, vals);
}

static VALUE
rb_instruction_id(VALUE self) {
  rb_evoasm_inst *inst;
  TypedData_Get_Struct(self, rb_evoasm_inst, &rb_inst_type, inst);

  return UINT2NUM(inst->inst->id);
}

static VALUE
rb_x64_instruction_flags(VALUE self) {
  rb_evoasm_x64_inst *inst;
  TypedData_Get_Struct(self, rb_evoasm_x64_inst, &rb_x64_inst_type, inst);

  return ULL2NUM(inst->inst->flags);
}


static VALUE
rb_x64_instruction_operands(VALUE self) {
  rb_evoasm_x64_inst *inst;
  unsigned i;
  VALUE *vals;

  TypedData_Get_Struct(self, rb_evoasm_x64_inst, &rb_x64_inst_type, inst);

  if(inst->inst->n_operands == 0) {
    return rb_ary_new();
  }

  vals = ALLOC_N(VALUE, inst->inst->n_operands);

  for(i = 0; i < inst->inst->n_operands; i++) {
    vals[i] = TypedData_Wrap_Struct(cX64Operand, &rb_x64_op_type, (void *)&inst->inst->operands[i]);
  }
  return rb_ary_new_from_values(inst->inst->n_operands, vals);
}

static VALUE
rb_x64_instruction_features(VALUE self) {
  rb_evoasm_x64_inst *inst;
  TypedData_Get_Struct(self, rb_evoasm_x64_inst, &rb_x64_inst_type, inst);

  return ULL2NUM(inst->inst->features);
}

static VALUE
rb_x64_instruction_name(VALUE self) {
  rb_evoasm_x64_inst *inst;
  TypedData_Get_Struct(self, rb_evoasm_x64_inst, &rb_inst_type, inst);

  return ID2SYM(rb_x64_inst_ids[((evoasm_inst *)inst->inst)->id]);
}

static VALUE
rb_x64_instruction_encode(VALUE self, VALUE rb_params) {
  rb_evoasm_x64_inst *inst;
  evoasm_x64 *x64;

  TypedData_Get_Struct(self, rb_evoasm_x64_inst, &rb_x64_inst_type, inst);
  TypedData_Get_Struct(inst->arch, evoasm_x64, &rb_x64_type, x64);

  return x64_instruction_encode(inst->inst, x64, rb_params);
}

static VALUE
rb_instruction_parameters(VALUE self) {
  rb_evoasm_inst *inst;
  uint16_t i;
  VALUE *vals;

  TypedData_Get_Struct(self, rb_evoasm_inst, &rb_inst_type, inst);

  if(inst->inst->params_len == 0) {
    return rb_ary_new();
  }

  vals = ALLOC_N(VALUE, inst->inst->params_len);

  for(i = 0; i < inst->inst->params_len; i++) {
    vals[i] = TypedData_Wrap_Struct(cParameter, &rb_param_type, (void *)&inst->inst->params[i]);
  }
  return rb_ary_new_from_values(inst->inst->params_len, vals);
}

VALUE rb_evoasm_log_level;

static VALUE
rb_evoasm_log_level_set(VALUE self, VALUE level) {
  evoasm_log_level prev_level = evoasm_min_log_level;
  evoasm_min_log_level = (evoasm_log_level)
                         EVOASM_CLAMP(FIX2INT(level),
                         EVOASM_MIN_LOG_LEVEL, EVOASM_N_LOG_LEVELS - 1);

  fprintf(stderr, "%d\n", evoasm_min_log_level);
  return INT2FIX(prev_level);
}

extern const uint16_t evoasm_n_domains;

void Init_evoasm_ext() {
  mEvoasm = rb_define_module("Evoasm");

  cArchitecture = rb_define_class_under(mEvoasm, "Architecture", rb_cData);
  cX64 = rb_define_class_under(mEvoasm, "X64", cArchitecture);
  cParameter = rb_define_class_under(mEvoasm, "Parameter", rb_cData);
  cRegister = rb_define_class_under(mEvoasm, "Register", rb_cData);
  cX64Register = rb_define_class_under(cX64, "Register", cRegister);
  cOperand = rb_define_class_under(mEvoasm, "Operand", rb_cData);
  cX64Operand = rb_define_class_under(cX64, "Operand", cOperand);
  cBuffer = rb_define_class_under(mEvoasm, "Buffer", rb_cData);
  cSearch = rb_define_class_under(mEvoasm, "Search", rb_cData);
  cProgram = rb_define_class_under(mEvoasm, "Program", rb_cData);
  cKernel = rb_define_class_under(mEvoasm, "Kernel", rb_cData);
  cParameters = rb_define_class_under(mEvoasm, "Parameters", rb_cData);
  cX64Parameters = rb_define_class_under(cX64, "Parameters", cParameters);
  cInstruction = rb_define_class_under(mEvoasm, "Instruction", rb_cData);
  evoasm_cX64Instruction = rb_define_class_under(cX64, "Instruction", cInstruction);

  rb_define_singleton_method(mEvoasm, "log_level=", rb_evoasm_log_level_set, 1);

  eError = rb_define_class_under(mEvoasm, "Error", rb_eStandardError);
  eArchitectureError = rb_define_class_under(cArchitecture, "Error", eError);
  rb_define_method(eError, "code", RUBY_METHOD_FUNC(rb_error_code), 0);
  rb_define_method(eError, "__message", RUBY_METHOD_FUNC(rb_error_message), 0);
  rb_define_method(eArchitectureError, "code", RUBY_METHOD_FUNC(rb_architecture_error_code), 0);
  rb_define_method(eArchitectureError, "parameter", RUBY_METHOD_FUNC(rb_architecture_error_parameter), 0);
  rb_define_method(eArchitectureError, "register", RUBY_METHOD_FUNC(rb_architecture_error_register), 0);
  rb_define_method(eArchitectureError, "instruction", RUBY_METHOD_FUNC(rb_architecture_error_instruction), 0);
  rb_define_method(eArchitectureError, "architecture", RUBY_METHOD_FUNC(rb_architecture_error_architecture), 0);

  evoasm_x64_ruby_define_consts();

  error_code_unknown = rb_intern("unknown");
  error_code_not_encodable = rb_intern("not_encodable");
  error_code_missing_param = rb_intern("missing_param");
  error_code_invalid_access = rb_intern("invalid_access");
  error_code_missing_feature = rb_intern("missing_feature");

  rb_define_alloc_func(cBuffer, rb_buffer_alloc);
  rb_define_method(cBuffer, "initialize", rb_buffer_initialize, -1);
  rb_define_method(cBuffer, "size", RUBY_METHOD_FUNC(rb_buffer_size), 0);
  rb_define_method(cBuffer, "reset!", RUBY_METHOD_FUNC(rb_buffer_reset), 0);
  rb_define_method(cBuffer, "to_s", RUBY_METHOD_FUNC(rb_buffer_to_s), 0);
#ifdef HAVE_CAPSTONE_CAPSTONE_H
  rb_define_method(cBuffer, "disassemble", rb_buffer_disassemble, 0);
#endif

  rb_define_alloc_func(cSearch, rb_search_alloc);
  rb_define_private_method(cSearch, "__initialize__", rb_search_initialize, -1);
  rb_define_method(cSearch, "start!", rb_search_start, 1);

#if 0
  rb_define_method(cX64, "rw!", RUBY_METHOD_FUNC(rb_buffer_rw), 0);
  rb_define_method(cX64, "rx!", RUBY_METHOD_FUNC(rb_buffer_rx), 0);
#endif

  rb_define_alloc_func(cProgram, rb_program_alloc);
  rb_define_method(cProgram, "buffer", rb_program_buffer, -1);
  rb_define_method(cProgram, "kernels", rb_program_kernels, 0);
  rb_define_private_method(cProgram, "__run__", rb_program_run, 2);
  rb_define_method(cProgram, "eliminate_introns!", rb_program_eliminate_introns_bang, 0);
  rb_define_method(cProgram, "output_registers", rb_program_output_registers, 0);
  
  rb_define_alloc_func(cKernel, rb_kernel_alloc);
  rb_define_method(cKernel, "parameters", rb_kernel_parameters, 0);
  rb_define_method(cKernel, "instructions", rb_kernel_instructions, 0);

  rb_define_method(cParameter, "domain", rb_parameter_domain, 0);
  rb_define_method(cParameter, "name", rb_parameter_name, 0);
  rb_define_method(cParameter, "id", rb_parameter_id, 0);

  rb_define_method(cX64Register, "id", rb_x64_register_id, 0);
  rb_define_method(cX64Register, "name", rb_x64_register_name, 0);
  rb_define_method(cX64Register, "type", rb_x64_register_type, 0);

  rb_define_method(cX64Operand, "type", rb_x64_operand_type, 0);
  rb_define_method(cX64Operand, "written?", rb_x64_operand_written_p, 0);
  rb_define_method(cX64Operand, "read?", rb_x64_operand_read_p, 0);
  rb_define_method(cX64Operand, "register", rb_x64_operand_register, 0);
  rb_define_method(cX64Operand, "size", rb_x64_operand_size, 0);

  rb_define_method(cInstruction, "id", rb_instruction_id, 0);
  rb_define_method(cInstruction, "parameters", rb_instruction_parameters, 0);

  rb_define_method(evoasm_cX64Instruction, "encode", rb_x64_instruction_encode, 0);
  rb_define_method(evoasm_cX64Instruction, "name", rb_x64_instruction_name, 0);
  rb_define_method(evoasm_cX64Instruction, "flags", rb_x64_instruction_flags, 0);
  rb_define_method(evoasm_cX64Instruction, "features", rb_x64_instruction_features, 0);
  rb_define_method(evoasm_cX64Instruction, "operands", rb_x64_instruction_operands, 0);

  rb_define_alloc_func(cX64, rb_x64_alloc);
  rb_define_method(cX64, "initialize", rb_x64_initialize, 0);
  rb_define_method(cX64, "encode", rb_x64_encode, -1);
#ifdef HAVE_CAPSTONE_CAPSTONE_H
  rb_define_singleton_method(cX64, "disassemble", rb_x64_s_disassemble, 1);
#endif

  rb_define_method(cArchitecture, "instructions", RUBY_METHOD_FUNC(rb_architecture_instructions), 0);

  rb_define_alloc_func(cX64Parameters, rb_x64_parameters_alloc);
  rb_define_method(cX64Parameters, "initialize", rb_x64_parameters_initialize, -1);

  rb_define_method(cX64Parameters, "[]=", RUBY_METHOD_FUNC(rb_x64_parameters_aset), 2);
  rb_define_method(cX64Parameters, "[]", RUBY_METHOD_FUNC(rb_x64_parameters_aref), 1);

  rb_define_const(mEvoasm,
      "ARCH_X64", UINT2NUM(EVOASM_ARCH_X64));

  domains_cache = rb_ary_new2(evoasm_n_domains);
  rb_ary_resize(domains_cache, evoasm_n_domains);
  rb_gc_register_address(&domains_cache);

  instructions_cache = rb_ary_new2(EVOASM_X64_N_INSTS);
  rb_ary_resize(instructions_cache, EVOASM_X64_N_INSTS);
  rb_gc_register_address(&instructions_cache);

  rb_id_brute_force = rb_intern("brute_force");
  rb_id_genetic = rb_intern("genetic");
  rb_id_id = rb_intern("id");

  evoasm_init(0, NULL, stderr);
}
