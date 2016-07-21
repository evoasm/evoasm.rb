require 'evoasm/adf'

module Evoasm
  class Search < FFI::AutoPointer
    attr_reader :architecture

    class Parameters
      ATTRS = %i(instructions kernel_size examples
                 adf_size population_size parameters
                 mutation_rate seed32 seed64 domains recur_limit)

      attr_accessor *ATTRS

      def initialize
        @mutation_rate = 0.1
        @seed64 = (1..16).to_a
        @seed32 = (1..4).to_a
        @recur_limit = 100
        @domains = {}
      end

      def missing
        ATTRS.select do |attr|
          send(attr).nil?
        end
      end
    end

    module Util
    end

    def initialize(architecture, &block)
      @archictecture = architecture

      parameters = Parameters.new
      block[parameters]

      missing_parameters = parameters.missing
      unless missing_parameters.empty?
        raise ArgumentError, "missing parameters: #{missing_parameters.join ', '}"
      end

      ptr = Libevoasm.search_alloc
      Libevoasm.search_init ptr, architecture, Libevoasm::SearchParams.new(architecture, parameters)

      super(ptr)
    end

    def start!(&block)
      func = FFI::Function.new(:bool, [:pointer, :double, :pointer]) do |adf_ptr, loss, _user_data|
        block[ADF.new(adf_ptr), loss]
      end

      Libevoasm.search_start self, func, nil
    end

    def self.release(ptr)
      Libevoasm.search_destroy(ptr)
      Libevoasm.search_free(ptr)
    end

    include Util
  end
end
