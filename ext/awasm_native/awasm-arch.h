#pragma once

#include <stdint.h>
#include "awasm-error.h"
#include "awasm-param.h"
#include "awasm-buf.h"
#include "awasm-log.h"

#define AWASM_ARCH_BUF_CAPA 32
#define AWASM_ARCH_MAX_PARAMS 64

typedef uint8_t awasm_reg_id;
typedef uint8_t awasm_operand_size;
typedef uint16_t awasm_inst_id;

struct awasm_arch;
struct awasm_inst;

typedef uint16_t (*awasm_arch_insts_func)(struct awasm_arch *arch, const struct awasm_inst **insts);

typedef enum {
  AWASM_ARCH_X64
} awasm_arch_id;

typedef struct {
  awasm_arch_id id : 8;
  uint16_t n_insts;
  uint8_t n_params;
  uint8_t max_inst_len;
  awasm_arch_insts_func insts_func;
} awasm_arch_cls;

typedef enum {
  AWASM_ARCH_ERROR_CODE_NOT_ENCODABLE = AWASM_N_ERROR_CODES,
  AWASM_ARCH_ERROR_CODE_MISSING_PARAM,
  AWASM_ARCH_ERROR_CODE_INVALID_ACCESS,
  AWASM_ARCH_ERROR_CODE_MISSING_FEATURE,
} awasm_arch_error_code;

struct awasm_arch;

typedef struct {
  struct awasm_arch *arch;
  uint8_t reg;
  uint8_t param;
  uint16_t inst;
} awasm_arch_error_data;

_Static_assert(sizeof(awasm_error_data) >= sizeof(awasm_arch_error_data), "awasm_arch_error_data exceeds awasm_error_data size limit");

typedef struct {
  AWASM_ERROR_HEADER
  awasm_arch_error_data data;
} awasm_arch_error;

typedef struct awasm_arch {
  awasm_arch_cls *cls;
  uint8_t buf_end;
  uint8_t buf_start;
  uint8_t buf[AWASM_ARCH_BUF_CAPA];
  void *user_data;
  /* must have a bit for every
   * writable register    */
  awasm_bitmap128 acc;
} awasm_arch;

typedef bool (*awasm_inst_encode_func)(awasm_arch *arch, awasm_arch_param_val *param_vals, awasm_bitmap *set_params);

typedef struct awasm_inst {
  awasm_inst_id id;
  uint16_t params_len;
  awasm_arch_param *params;
  awasm_inst_encode_func encode_func;
} awasm_inst;

uint16_t
awasm_arch_insts(awasm_arch *arch, const awasm_inst **insts);

awasm_success
awasm_inst_encode(awasm_inst *inst, awasm_arch *arch, awasm_arch_param_val *param_vals, awasm_bitmap *set_params);

void
awasm_arch_reset(awasm_arch *arch);

void
awasm_arch_init(awasm_arch *arch, awasm_arch_cls *cls);

void
awasm_arch_destroy(awasm_arch *arch);

void
awasm_arch_save(awasm_arch *arch, awasm_buf *buf);

static inline void
awasm_arch_write8(awasm_arch *arch, int64_t datum) {
  uint8_t new_end = (uint8_t)(arch->buf_end + 1);
  *((uint8_t *)(arch->buf + arch->buf_end)) = (uint8_t) datum;
  arch->buf_end = new_end;
}

static inline void
awasm_arch_write16(awasm_arch *arch, int64_t datum) {
  uint8_t new_end = (uint8_t)(arch->buf_end + 2);
  *((int16_t *)(arch->buf + arch->buf_end)) = (int16_t) datum;
  arch->buf_end = new_end;
}

static inline void
awasm_arch_write32(awasm_arch *arch, int64_t datum) {
  uint8_t new_end = (uint8_t)(arch->buf_end + 4);
  *((int32_t *)(arch->buf + arch->buf_end)) = (int32_t) datum;
  arch->buf_end = new_end;
}

static inline void
awasm_arch_write64(awasm_arch *arch, int64_t datum) {
  uint8_t new_end = (uint8_t)(arch->buf_end + 8);
  *((int64_t *)(arch->buf + arch->buf_end)) = (int64_t) datum;
  arch->buf_end = new_end;
}

static inline void
awasm_arch_write_access(awasm_arch *arch, awasm_bitmap *acc, awasm_reg_id reg) {
  awasm_bitmap_set(acc, (unsigned) reg);
}

static inline void
awasm_arch_undefined_access(awasm_arch *arch, awasm_bitmap *acc, awasm_reg_id reg) {
  awasm_bitmap_unset(acc, (unsigned) reg);
}

static inline awasm_success
_awasm_arch_read_access(awasm_arch *arch, awasm_bitmap *acc, awasm_reg_id reg, awasm_inst_id inst, const char *file, unsigned line) {
  if(!awasm_bitmap_get(acc, (unsigned) reg)) {
    awasm_arch_error_data error_data = {
      .reg = (uint8_t) reg,
      .inst = (uint16_t) inst,
      .arch = arch
    };
    awasm_set_error(AWASM_ERROR_TYPE_ARCH, AWASM_ARCH_ERROR_CODE_INVALID_ACCESS, &error_data, file, line, "read access violation");
    return false;
  }
  return true;
}

#define awasm_arch_read_access(arch, acc, reg, inst) _awasm_arch_read_access(arch, acc, reg, inst, __FILE__, __LINE__)
