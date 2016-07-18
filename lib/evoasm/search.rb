require 'evoasm/core_ext/array'

module Evoasm
  class Search < FFI::AutoPointer

    class Parameters
      attr_accessor :instructions, :kernel_size,
                    :program_size, :population_size, :parameters,
                    :mutation_rate, :seed32, :seed64, :domains, :recur_limit

      def initialize
        @mutation_rate = 0.1
        @seed64 = (1..16).to_a
        @seed32 = (1..4).to_a
        @recur_limit = 100
      end

      def examples(*examples)
        if examples.empty?
          @examples
        else
          @examples = examples
        end
      end
    end

    module Util
      def convert_examples(examples)
        arity = determine_arity examples
        types = determine_types examples

        [examples.flatten, arity, types]
      end

      def determine_types(examples)
        types = nil
        examples.each do |example|
          example_types = example.map do |value|
            case value
            when Float
              :f64
            when Integer
              :i64
            else
              raise ArgumentError,
                    "invalid example value '#{value}' of type '#{value.class}'"
            end
          end
          if types && example_types != types
            raise ArgumentError,
                  "invalid example types '#{example_types.inspect}' (expected '#{types.inspect}')"
          end
          types = example_types
        end
      end

      def determine_arity(examples)
        arity = nil
        examples.each do |example|
          example_arity = Array(example).size
          if arity && arity != example_arity
            raise ArgumentError,
                  "invalid arity for example '#{example}' (#{example_arity} for #{arity})"
          end
          arity = example_arity
        end
        arity
      end
    end

    def initialize(arch, &block)
      params = Parameters.new
      block[params]

      ptr = Libevoasm.search_alloc
      Libevoasm.search_init ptr, arch, convert_parameters params

      super(ptr)
    end


    def self.release(ptr)
      Libevoasm.search_destroy(ptr)
      Libevoasm.search_free(ptr)
    end

    include Util

    private
    def convert_parameters(parameters)
      params = Libevoasm::SearchParams.new

      params.mut_rate = parameters.mutation_rate
      params.insts = parameters.instructions
      params.kernel_size = parameters.kernel_size
      params.program_size = parameters.program_size
      params.pop_size = parameters.population_size
      params.mut_rate = (parameters.mutation_rate * Libevoasm::INT32_MAX).to_i
      params.seed32 = parameters.seed32
      params.seed64 = parameters.seed64
      params.recur_limit = parameters.recur_limit
      params.domains = parameters.domains

      input_examples, output_examples = examples.keys, examples.values
      input_examples, input_arity, input_types = convert_examples input_examples
      output_examples, output_arity, output_types = convert_examples output_examples

      program_output = Libevoasm::ProgramOutput.new
      program_output.arity = output_arity
      program_output.len = output_examples.size
      program_output.types = output_types

      program_input = Libevoasm::ProgramInput.new
      program_input.arity = input_arity
      program_input.len = input_examples.size
      program_input.types = input_types

      params.program_input = program_input
      params.program_output = program_output

      params
    end
  end
end
