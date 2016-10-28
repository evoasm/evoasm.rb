require 'evoasm/error'
require 'ffi'

module Evoasm
  class Population < FFI::AutoPointer

    def self.release(ptr)
      Libevoasm.pop_destroy(ptr)
      Libevoasm.pop_free(ptr)
    end

    def initialize(architecture, parameters = nil)
      @parameters = parameters || Parameters.new(architecture)

      ptr = Libevoasm.pop_alloc
      unless Libevoasm.pop_init ptr, architecture, @parameters
        raise Error.last
      end

      super(ptr)
    end

    def evaluate
      unless Libevoasm.pop_eval self
        raise Error.last
      end
    end

    def seed
      Libevoasm.pop_seed self
    end

    def summary
      summary_len = Libevoasm.pop_summary_len pop
      summary = FFI::MemoryPointer.new :loss, summary_len
      summary = Libevoasm.pop_calc_summary self, summary
      summary.each_slice(5).to_a
    end

    def next_generation!
      Libevoasm.pop_next_gen self
    end
  end
end

require 'evoasm/population/parameters'
