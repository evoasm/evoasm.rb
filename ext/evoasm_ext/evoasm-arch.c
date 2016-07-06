#include "evoasm-arch.h"
#include "evoasm-util.h"
#include <string.h>
#include <inttypes.h>

EVOASM_DECL_LOG_TAG("arch")

evoasm_success
evoasm_inst_encode(evoasm_inst *inst, evoasm_arch *arch, evoasm_arch_param_val *param_vals, evoasm_bitmap *set_params) {
  return inst->encode_func(arch, param_vals, set_params);
}

uint16_t
evoasm_arch_insts(evoasm_arch *arch, const evoasm_inst **insts) {
  return arch->cls->insts_func(arch, insts);
}

void
evoasm_arch_reset(evoasm_arch *arch) {
  arch->buf_start = EVOASM_ARCH_BUF_CAPA / 2;
  arch->buf_end   = EVOASM_ARCH_BUF_CAPA / 2;
}

void
evoasm_arch_init(evoasm_arch *arch, evoasm_arch_cls *cls) {
  static evoasm_arch zero_arch = {0};
  *arch = zero_arch;
  evoasm_arch_reset(arch);
  arch->cls = cls;
}

void
evoasm_arch_destroy(evoasm_arch *arch) {
}

void
evoasm_arch_save(evoasm_arch *arch, evoasm_buf *buf) {
  uint8_t len = (uint8_t)(arch->buf_end - arch->buf_start);

  memcpy(buf->data + buf->pos, arch->buf + arch->buf_start, len);
  buf->pos += len;

  evoasm_arch_reset(arch);
}
