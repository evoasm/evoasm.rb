#include "awasm-arch.h"
#include "awasm-util.h"
#include <string.h>
#include <inttypes.h>

AWASM_DECL_LOG_TAG("arch")

awasm_success
awasm_inst_encode(awasm_inst *inst, awasm_arch *arch, awasm_arch_param_val *param_vals, awasm_bitmap *set_params) {
  return inst->encode_func(arch, param_vals, set_params);
}

uint16_t
awasm_arch_insts(awasm_arch *arch, const awasm_inst **insts) {
  return arch->cls->insts_func(arch, insts);
}

void
awasm_arch_reset(awasm_arch *arch) {
  arch->buf_start = AWASM_ARCH_BUF_CAPA / 2;
  arch->buf_end   = AWASM_ARCH_BUF_CAPA / 2;
}

void
awasm_arch_init(awasm_arch *arch, awasm_arch_cls *cls) {
  static awasm_arch zero_arch = {0};
  *arch = zero_arch;
  awasm_arch_reset(arch);
  arch->cls = cls;
}

void
awasm_arch_destroy(awasm_arch *arch) {
}

void
awasm_arch_save(awasm_arch *arch, awasm_buf *buf) {
  uint8_t len = (uint8_t)(arch->buf_end - arch->buf_start);

  memcpy(buf->data + buf->pos, arch->buf + arch->buf_start, len);
  buf->pos += len;

  awasm_arch_reset(arch);
}
