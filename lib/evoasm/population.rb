require 'evoasm/error'
require 'ffi'

module Evoasm
  class Population < FFI::AutoPointer

    def self.release(ptr)
      Libevoasm.pop_destroy(ptr)
      Libevoasm.pop_free(ptr)
    end

    def initialize(architecture, parameters)
      @parameters = parameters

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

    def best_loss
      Libevoasm.pop_get_best_loss self
    end

    def best_program
      program = Program.new
      unless Libevoasm.pop_load_best_program self, program
        raise Error.last
      end

      program
    end

    def loss_samples
      Array.new(@parameters.deme_count) do |deme_index|
        data_ptr_ptr = FFI::MemoryPointer.new :pointer, 1
        len = Libevoasm.pop_get_loss_samples self, deme_index, data_ptr_ptr
        data_ptr = data_ptr_ptr.read_pointer
        data_ptr.read_array_of_float len
      end
    end

    def summary
      summary_len = Libevoasm.pop_summary_len self
      summary = FFI::MemoryPointer.new :float, summary_len
      unless Libevoasm.pop_calc_summary self, summary
        raise Error.last
      end
      summary.read_array_of_float(summary_len).each_slice(summary_len / @parameters.deme_count).map{|deme_summary| deme_summary.each_slice(5).to_a}.to_a
    end

    def next_generation!
      Libevoasm.pop_next_gen self
    end
  end
end

require 'evoasm/population/parameters'
