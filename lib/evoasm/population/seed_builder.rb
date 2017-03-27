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

        def kernel(name, &block)
          @kernels[name] = Kernel.new self, &block
        end
      end

      class Kernel
        attr_reader :program

        def initialize(program, &block)
          @program = program
          @instructions = []
          @j
          instance_eval &block
        end

        def respond_to_missing?(name, *args, **kwargs, &block)
          return true if program.builder.instructions.include? name
          false
        end

        def method_missing(name, *args, **kwargs, &block)
          if program.builder.instructions.include? name
            @instructions << [name, kwargs]
          elsif program.
            super
          end
        end
      end

      def initialize(architecture, instructions, &block)
        @architecture = architecture
        @instructions = instructions

        @programs = {}

        instance_eval &block
      end

      def build

      end

      def program(name, &block)
        @programs[name] = Program.new self, &block
      end
    end
  end
end
