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

      seed_ptr = FFI::MemoryPointer.new :uint64, SEED_SIZE
      seed_ptr.write_array_of_uint64 seed

      Libevoasm.prng_init ptr, seed_ptr
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