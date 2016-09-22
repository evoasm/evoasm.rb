require 'evoasm/deme/parameters'
require 'evoasm/prng'
require 'evoasm/program/io'

module Evoasm
  class ProgramDeme
    class Parameters < Deme::Parameters

      def self.release(ptr)
        Libevoasm.program_deme_params_free ptr
      end

      attr_reader :input, :output

      def initialize(architecture)
        ptr = Libevoasm.program_deme_params_alloc
        Libevoasm.program_deme_params_init ptr

        case architecture
        when :x64
          @inst_id_enum_type = Libevoasm.enum_type :x64_inst_id
          @param_id_enum_type = Libevoasm.enum_type :x64_param_id
        else
          raise "unknown architecture #{architecture}"
        end

        super(ptr)
      end

      def instructions=(instructions)
        instructions.each_with_index do |instruction, index|
          name =
            if instruction.is_a? Symbol
              instruction
            else
              instruction.name
            end
          Libevoasm.program_deme_params_set_inst(self, index, name)
        end
        Libevoasm.program_deme_params_set_n_insts(self, instructions.size)
      end

      def instructions
        Array.new(Libevoasm.program_deme_params_n_insts self) do |index|
          @inst_id_enum_type[Libevoasm.program_deme_params_inst(self, index)]
        end
      end

      %w(kernel_size kernel_count).each do |attr_name|
        define_method attr_name do
          min = Libevoasm.send "program_deme_params_min_#{attr_name}", self
          max = Libevoasm.send "program_deme_params_max_#{attr_name}", self

          if min == max
            return min
          else
            return (min..max)
          end
        end

        define_method "#{attr_name}=" do |value|
          case value
          when Range
            min = value.min
            max = value.max
          else
            min = value
            max = value
          end
          Libevoasm.send "program_deme_params_set_min_#{attr_name}", self, min
          Libevoasm.send "program_deme_params_set_max_#{attr_name}", self, max
        end
      end

      def recur_limit
        Libevoasm.program_deme_params_recur_limit self
      end

      def recur_limit=(recur_limit)
        Libevoasm.program_deme_params_set_recur_limit self, recur_limit
      end

      def examples=(examples)
        input_examples = examples.keys.map { |k| Array(k) }
        output_examples = examples.values.map { |k| Array(k) }

        self.input = Program::Input.new input_examples
        self.output = Program::Output.new output_examples
      end

      def input=(input)
        @input = input
        Libevoasm.program_deme_params_set_program_input self, input
      end

      def output=(output)
        @output = output
        Libevoasm.program_deme_params_set_program_output self, output
      end

      def examples
        input.zip(output).to_h
      end

      private
      def parameters_enum_type
        @param_id_enum_type
      end
    end
  end
end
