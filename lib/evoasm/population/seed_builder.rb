module Evoasm
  class Population
    class SeedBuilder

      attr_reader :instructions

      class Program
        attr_reader :builder

        def initialize(builder, &block)
          @builder = builder
          @kernels = {}

          instance_eval &block
        end

        def kernel(name = @kernels.size, &block)
          @kernels[name] = Kernel.new self, &block
        end
      end

      class Kernel
        attr_reader :program

        def initialize(program, &block)
          @program = program
          @instructions = []
          @topology = []
          instance_eval &block
        end

        def respond_to_missing?(name, *args, **kwargs, &block)
          return true if program.builder.instructions.include? name
          false
        end

        def method_missing(name, *args, **kwargs, &block)
          if program.builder.instruction_name? name
            if program.builder.allowed_instruction_name? name
              @instructions << [name, kwargs]
            else
              raise ArgumentError, "'#{name}' is not in the current instruction set"
            end
          elsif program.builder.jump_condition? name
            @topology << [name, *args]
          else
            super
          end
        end
      end

      def initialize(architecture, instructions, &block)
        @architecture = architecture
        @instructions = instructions

        case architecture
        when :x64
          @jmp_cond_enum_type = Libevoasm.enum_type :x64_jmp_cond
          @inst_id_enum_type = Libevoasm.enum_type :x64_inst_id
        else
          raise
        end

        @programs = {}

        instance_eval &block
      end

      def jump_condition?(name)
        !@jmp_cond_enum_type[name].nil?
      end

      def instruction_name?(name)
        !@inst_id_enum_type[name].nil?
      end

      def allowed_instruction_name?(name)
        @instructions.include? name
      end

      def build

      end

      def program(name = @programs.size, &block)
        @programs[name] = Program.new self, &block
      end
    end
  end
end
