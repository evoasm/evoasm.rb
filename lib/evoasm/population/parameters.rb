require 'evoasm/prng'
require 'evoasm/program/io'
require 'evoasm/domain'

module Evoasm
  class Population
    class Parameters < FFI::AutoPointer

      # @!visibility private
      def self.release(ptr)
        Libevoasm.pop_params_free ptr
      end

      # @return [Program::Input] input examples
      attr_reader :input

      # @return [Program::Output] output examples
      attr_reader :output

      # @param architecture [Symbol] the machine architecture (currently only +:x64+ is supported)
      # @yield [self]
      def initialize(architecture, &block)
        ptr = Libevoasm.pop_params_alloc
        Libevoasm.pop_params_init ptr

        case architecture
        when :x64
          @inst_id_enum_type = Libevoasm.enum_type :x64_inst_id
          @param_id_enum_type = Libevoasm.enum_type :x64_param_id
        else
          raise "unknown architecture #{architecture}"
        end

        super(ptr)

        self.seed = PRNG::DEFAULT_SEED

        if block
          block[self]
        end
      end

      # @!attribute mutation_rate
      # @return [Float 0..1] the mutation rate
      def mutation_rate
        Libevoasm.pop_params_get_mut_rate(self)
      end

      def mutation_rate=(mutation_rate)
        Libevoasm.pop_params_set_mut_rate self, mutation_rate
      end

      # @!attribute deme_size
      # @return [Integer] the number of individuals per deme
      def deme_size
        Libevoasm.pop_params_get_deme_size self
      end

      def deme_size=(deme_size)
        Libevoasm.pop_params_set_deme_size self, deme_size
      end

      # @!attribute deme_count
      # @return [Integer] the number of demes in the population
      def deme_count
        Libevoasm.pop_params_get_n_demes self
      end

      def deme_count=(deme_count)
        Libevoasm.pop_params_set_n_demes self, deme_count
      end

      # @!attribute parameters
      # @return [Array<Symbol>] the list of architecture-dependent instruction parameters to use
      def parameters
        Array.new(Libevoasm.pop_params_get_n_params self) do |index|
          parameters_enum_type[Libevoasm.pop_params_get_param(self, index)]
        end
      end

      def parameters=(parameter_names)
        parameter_names.each_with_index do |parameter_name, index|
          Libevoasm.pop_params_set_param(self, index, parameters_enum_type[parameter_name])
        end
        Libevoasm.pop_params_set_n_params(self, parameter_names.size)
      end

      # @!attribute domains
      # @return [Hash{Symbol => Array, Range}] a hash whose values indicate user-defined domains for the parameters given as keys
      def domains
        parameters.map do |parameter_name|
          domain_ptr = Libevoasm.pop_params_get_domain(self, parameter_name)
          domain = @domains.find { |domain| domain == domain_ptr }
          [parameter_name, domain]
        end.to_h
      end

      def domains=(domains_hash)
        domains = []
        domains_hash.each do |parameter_name, domain_value|
          domain = Domain.for domain_value
          success = Libevoasm.pop_params_set_domain(self, parameter_name, domain)
          if !success
            raise ArgumentError, "no such parameter #{parameter_name}"
          end
          domains << domain
        end

        # keep reference to prevent disposal by GC
        @domains = domains
      end

      # @!visibility private
      def deme_height
        Libevoasm.pop_params_get_deme_height self
      end

      # @!attribute seed
      # @return [Array<Integer>] the seed for the random number generator
      def seed
        Array.new(PRNG::SEED_SIZE) do |index|
          Libevoasm.pop_params_get_seed(self, index)
        end
      end

      def seed=(seed)
        if seed.size != PRNG::SEED_SIZE
          raise ArgumentError, 'invalid seed size'
        end

        seed.each_with_index do |seed_value, index|
          Libevoasm.pop_params_set_seed(self, index, seed_value)
        end
      end

      # Validate the parameters
      # @raise [Error] if the parameters are invalid
      def validate!
        unless Libevoasm.pop_params_validate(self)
          raise Error.last
        end
      end

      # @!attribute instructions
      # @return [Symbol, Instruction] the list of instructions to use
      def instructions
        Array.new(Libevoasm.pop_params_get_n_insts self) do |index|
          @inst_id_enum_type[Libevoasm.pop_params_get_inst(self, index)]
        end
      end
      def instructions=(instructions)
        instructions.each_with_index do |instruction, index|
          name =
            if instruction.is_a? Symbol
              instruction
            else
              instruction.name
            end
          Libevoasm.pop_params_set_inst(self, index, name)
        end
        Libevoasm.pop_params_set_n_insts(self, instructions.size)
      end

      # @!attribute kernel_size
      # @return [Integer] the size of program kernels (number of instructions per kernel)
      def kernel_size
        Libevoasm.pop_params_get_kernel_size self
      end

      def kernel_size=(kernel_size)
        Libevoasm.pop_params_set_kernel_size self, kernel_size
      end

      # @!attribute program_size
      # @return [Integer] the size of programs (number of kernels per program)
      def program_size
        Libevoasm.pop_params_get_program_size self
      end

      def program_size=(program_size)
        Libevoasm.pop_params_set_program_size self, program_size
      end

      # @!attribute recur_limit
      # @return [Integer] the size of programs (number of kernels per program)
      def recur_limit
        Libevoasm.pop_params_get_recur_limit self
      end

      def recur_limit=(recur_limit)
        Libevoasm.pop_params_set_recur_limit self, recur_limit
      end

      # @!attribute examples
      # @return [Hash] shorthand to set expected program input and output
      # @see #input
      # @see #output
      def examples
        input.zip(output).to_h
      end

      def examples=(examples)
        input_examples = examples.keys.map { |k| Array(k) }
        output_examples = examples.values.map { |k| Array(k) }

        self.input = Program::Input.new input_examples
        self.output = Program::Output.new output_examples
      end

      def input=(input)
        @input = input
        Libevoasm.pop_params_set_program_input self, input
      end

      def output=(output)
        @output = output
        Libevoasm.pop_params_set_program_output self, output
      end

      private
      def parameters_enum_type
        @param_id_enum_type
      end
    end
  end
end
