#include "evoasm.h"
#include "evoasm-util.h"

//static const char *_evoasm_log_tag = "general";

void
evoasm_prng64_init(struct evoasm_prng64 *prng, evoasm_prng64_seed *seed) {
  prng->s = *seed;
}

void
evoasm_prng64_destroy(struct evoasm_prng64 *prng) {
}

void
evoasm_prng32_init(struct evoasm_prng32 *prng, evoasm_prng32_seed *seed) {
  prng->s = *seed;
}

void
evoasm_prng32_destroy(struct evoasm_prng32 *prng) {
}

