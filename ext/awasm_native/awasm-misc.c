#include "awasm.h"
#include "awasm-util.h"

//static const char *_awasm_log_tag = "general";

void
awasm_prng64_init(struct awasm_prng64 *prng, awasm_prng64_seed *seed) {
  prng->s = *seed;
}

void
awasm_prng64_destroy(struct awasm_prng64 *prng) {
}

void
awasm_prng32_init(struct awasm_prng32 *prng, awasm_prng32_seed *seed) {
  prng->s = *seed;
}

void
awasm_prng32_destroy(struct awasm_prng32 *prng) {
}

