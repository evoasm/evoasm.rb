module Evoasm
  class PRNG < FFI::AutoPointer
    SEED_SIZE = 16
    DEFAULT_SEED = (1..SEED_SIZE).to_a

    def self.release(ptr)
      Libevoasm.prng_free ptr
    end

    def initialize(seed = nil)
      seed ||= DEFAULT_SEED
      if seed.size != SEED_SIZE
        raise ArgumentError, "seed must be have exactly #{SEED_SIZE} elements"
      end

      ptr = Libevoasm.prng_alloc
      var_args = seed.flat_map { |seed_value| [:int64, seed_value] }
      Libevoasm.prng_init ptr, *var_args
      super(ptr)
    end

    def rand64
      Libevoasm.prng_rand64 self
    end

    def rand32
      Libevoasm.prng_rand32 self
    end

    def rand16
      Libevoasm.prng_rand16 self
    end

    def rand8
      Libevoasm.prng_rand8 self
    end

    def rand_between(min, max)
      Libevoasm.prng_rand_between self, min, max
    end
  end
end