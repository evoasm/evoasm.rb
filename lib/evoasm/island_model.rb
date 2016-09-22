require 'evoasm/program'
require 'evoasm/error'

module Evoasm
  class IslandModel < FFI::AutoPointer
    attr_reader :architecture

    def initialize(&block)
      @parameters = Parameters.new architecture
      block[@parameters]

      @parameters.validate!

      ptr = Libevoasm.island_model_alloc
      unless Libevoasm.island_model_init ptr, @parameters
        raise Error.last
      end

      super(ptr)
    end

    def progress(&block)
      @progress_func = FFI::Function.new(:bool, [:pointer, :pointer, :uint, :uint, :double, :uint, :pointer]) do |_island_model_ptr, island_ptr, cycle, gen, loss, n_inf, _user_data|
        block[find_island_by_address(island_model_ptr.address), cycle, gen, loss, n_inf]
      end
      Libevoasm.island_model_set_progress_cb(@progress_func)
    end

    def start(&block)
      result_func = FFI::Function.new(:bool, [:pointer, :double, :pointer]) do |program_ptr, loss, _user_data|
        block[Program.new(program_ptr), loss]
      end

      Libevoasm.island_model_start self, result_func, nil
    end

    def self.release(ptr)
      Libevoasm.program_deme_destroy(ptr)
      Libevoasm.program_deme_free(ptr)
    end

    private
    def find_island_by_address(address)

    end
  end
end

require 'evoasm/island_model/parameters'
