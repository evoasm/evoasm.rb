require 'evoasm/adf'
require 'evoasm/error'

module Evoasm
  class Search < FFI::AutoPointer
    attr_reader :architecture

    def initialize(architecture, &block)
      @architecture = architecture

      @parameters = Parameters.new architecture
      block[@parameters]

      @parameters.validate!

      ptr = Libevoasm.search_alloc
      unless Libevoasm.search_init ptr, architecture, @parameters
        raise Error.last
      end

      super(ptr)
    end

    def progress(&block)
      @progress_func = FFI::Function.new(:bool, [:uint, :uint, :uint, :double, :uint, :pointer]) do |pop_idx, cycle, gen, loss, n_inf, user_data|
        block[pop_idx, cycle, gen, loss, n_inf]
      end
    end

    def start!(&block)
      goal_func = FFI::Function.new(:bool, [:pointer, :double, :pointer]) do |adf_ptr, loss, _user_data|
        block[ADF.new(adf_ptr), loss]
      end

      Libevoasm.search_start self, @progress_func, goal_func, nil
    end

    def self.release(ptr)
      Libevoasm.search_destroy(ptr)
      Libevoasm.search_free(ptr)
    end
  end
end

require 'evoasm/search/parameters'
