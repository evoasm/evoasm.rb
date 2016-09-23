require 'evoasm/error'
require 'ffi'

module Evoasm
  class Deme < FFI::AutoPointer

    def evaluate(max_loss = 0.0, &block)
      result_callback = FFI::Function.new(:bool, [:pointer, :pointer, :double, :pointer]) do |_deme_ptr, individual_ptr, loss, _user_data|
        block[new_individual(individual_ptr), loss]
      end

      unless Libevoasm.deme_eval self, max_loss, result_callback, nil
        raise Error.last
      end
    end

    def seed
      Libevoasm.deme_seed self
    end

    def loss(per_example = true)
      n_inf_ptr = FFI::MemoryPointer.new :uint
      loss = Libevoasm.deme_get_loss self, n_inf_ptr, per_example
      n_inf = n_inf_ptr.read_uint

      [loss, n_inf]
    end

    def next_generation!
      unless Libevoasm.deme_next_gen self
        raise Error.last
      end
    end
  end
end
