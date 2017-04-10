module Evoasm
  class Population
    class SeedBuilder

      attr_reader :instructions
      attr_reader :population

      class Kernel
        attr_reader :instructions

        def initialize(builder, &block)
          @builder = builder
          @instructions = []

          instance_eval &block if block
        end

        def respond_to_missing?(name, *args, **kwargs, &block)
          return true if builder.instructions.include? name
          false
        end

        def default(default = nil)
          return @default if default.nil?
          @default = default
        end

        def method_missing(name, *args, **kwargs, &block)
          if builder.instruction_name? name
            if builder.allowed_instruction_name? name
              @instructions << [name, kwargs]
            else
              raise ArgumentError, "'#{name}' is not in the current instruction set"
            end
          else
            super
          end
        end
      end

      def seed_population!
        kernels = Libevoasm.deme_kernels_alloc
        success = Libevoasm.deme_kernels_init kernels, @population.parameters, architecture, @kernels.size

        unless success
          Libevoasm.deme_kernels_free kernels
          raise Error.last
        end

        @kernels.each do |kernel, kernel_index|
          kernel.instructions.each_with_index do |instruction, instruction_index|
            inst_id, params_hash = instruction
            parameters = Evoasm::X64::Parameters.new(params_hash, basic: true)
            Libevoasm.deme_kernels_set_inst kernels, kernel_index, instruction_index, inst_id, parameters
          end
          Libevoasm.deme_kernels_set_size kernels, kernel_index, kernel.instructions.size
        end

        success = Libevoasm.pop_seed @population, kernels

        Libevoasm.deme_kernels_free kernels

        unless success
          raise Error.last
        end
      end

      def architecture
        @population.architecture
      end

      def initialize(population, instructions, &block)
        @population = population
        @instructions = instructions

        case architecture
        when :x64
          @jmp_cond_enum_type = Libevoasm.enum_type :x64_jmp_cond
          @inst_id_enum_type = Libevoasm.enum_type :x64_inst_id
        else
          raise
        end

        @kernels = []

        instance_eval &block
      end

      def instruction_name?(name)
        !@inst_id_enum_type[name].nil?
      end

      def allowed_instruction_name?(name)
        @instructions.include? name
      end

      def kernel(&block)
        @kernels << Kernel.new(self, &block)
      end
    end
  end
end
