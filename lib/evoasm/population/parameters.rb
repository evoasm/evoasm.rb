require 'evoasm/prng'
require 'evoasm/kernel/io'
require 'evoasm/domain'

module Evoasm
  class Population

    class Parameters < FFI::AutoPointer
      DEFAULT_EXAMPLE_WINDOW_SIZE = 128

      # @!visibility private
      def self.release(ptr)
        Libevoasm.pop_params_free ptr
      end

      # @return [Kernel::Input] input examples
      attr_reader :input

      # @return [Kernel::Output] output examples
      attr_reader :output

      # @param architecture [Symbol] the machine architecture (currently only +:x64+ is supported)
      # @yield [self]
      def initialize(architecture = Evoasm.architecture, &block)
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
        self.example_window_size = DEFAULT_EXAMPLE_WINDOW_SIZE

        if block
          block[self]
        end
      end

      # @!attribute deme_size
      # @return [Integer] the number of individuals per deme
      def deme_size
        Libevoasm.pop_params_get_deme_size self
      end

      def deme_size=(deme_size)
        Libevoasm.pop_params_set_deme_size self, deme_size
      end

      # @!attribute example_window_size
      # @return [Integer] the size of the example window
      def example_window_size
        Libevoasm.pop_params_get_example_win_size self
      end

      def example_window_size=(example_window_size)
        Libevoasm.pop_params_set_example_win_size self, example_window_size
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
          unless success
            raise ArgumentError, "no such parameter #{parameter_name}"
          end
          domains << domain
        end

        # keep reference to prevent disposal by GC
        @domains = domains
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
      # @return [Range,Integer] range of possible kernel sizes
      def kernel_size
        min = Libevoasm.pop_params_get_min_kernel_size self
        max = Libevoasm.pop_params_get_max_kernel_size self

        return (min..max)
      end

      def kernel_size=(kernel_size)
        case kernel_size
        when Range
          Libevoasm.pop_params_set_min_kernel_size self, kernel_size.min
          Libevoasm.pop_params_set_max_kernel_size self, kernel_size.max
        when Integer
          Libevoasm.pop_params_set_min_kernel_size self, kernel_size
          Libevoasm.pop_params_set_max_kernel_size self, kernel_size
        else
          raise ArumgentError, 'kernel size must be range or integer'
        end
      end

      # @!attribute examples
      # @return [Hash] shorthand to set expected kernel input and output
      # @see #input
      # @see #output
      def examples
        input.zip(output).to_h
      end

      def examples=(examples)
        input_examples = examples.keys.map { |k| Array(k) }
        output_examples = examples.values.map { |k| Array(k) }

        self.input = Kernel::Input.new input_examples
        self.output = Kernel::Output.new output_examples
      end

      def input=(input)
        @input = input
        Libevoasm.pop_params_set_kernel_input self, input
      end

      def output=(output)
        @output = output
        Libevoasm.pop_params_set_kernel_output self, output
      end

      private
      def parameters_enum_type
        @param_id_enum_type
      end
    end
  end
end
