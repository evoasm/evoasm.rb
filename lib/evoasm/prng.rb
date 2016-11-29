module Evoasm
  # A fast pseudo-random number generator.
  class PRNG < FFI::AutoPointer

    # Number of seed elements required
    SEED_SIZE = 16

    # Default seed values
    DEFAULT_SEED = (1..SEED_SIZE).to_a

    # @!visibility private
    def self.release(ptr)
      Libevoasm.prng_free ptr
    end

    # Gives the default {PRNG}, seeded with {DEFAULT_SEED}
    # @return [PRNG] default {PRNG} instance
    def self.default
      @default_prng ||= new(DEFAULT_SEED)
    end

    # @param seed [Array<Integer>] the seed, must have exactly {SEED_SIZE} elements
    # @return [PRNG] new {PRNG} instance
    def initialize(seed)
      if seed.size != SEED_SIZE
        raise ArgumentError, "seed must be have exactly #{SEED_SIZE} elements"
      end

      ptr = Libevoasm.prng_alloc

      seed_ptr = FFI::MemoryPointer.new :uint64, SEED_SIZE
      seed_ptr.write_array_of_uint64 seed

      Libevoasm.prng_init ptr, seed_ptr
      super(ptr)
    end

    # @return [Integer] a random number in the range (0..2**64 - 2)
    def rand64
      Libevoasm.prng_rand64 self
    end

    # @return [Integer] a random number in the range (0..2**32 - 2)
    def rand32
      Libevoasm.prng_rand32 self
    end

    # @return [Integer] a random number in the range (0..2**16 - 2)
    def rand16
      Libevoasm.prng_rand16 self
    end

    # @return [Integer] a random number in the range (0..2**8 - 2)
    def rand8
      Libevoasm.prng_rand8 self
    end

    # Gives a random number in the range (+min+..+max+ - 1)
    # @return [Integer] random number
    def rand_between(min, max)
      Libevoasm.prng_rand_between self, min, max
    end
  end
end