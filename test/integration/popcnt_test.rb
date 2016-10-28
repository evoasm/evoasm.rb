require_relative 'program_deme_helper'

module Search
  class PopcntTest < Minitest::Test
    include SearchTests

    class Context < SearchContext
      def initialize
        instruction_names = Evoasm::X64.instruction_names(:gp, :rflags, population: true)

        @examples = {
          0b0 => 0,
          0b1 => 1,
          0b110 => 2,
          0b101 => 2,
          0b111 => 3,
          0b100 => 1,
          0b101010 => 3,
          0b1010 => 2,
          0b10000 => 1,
          0b100001 => 2,
          0b101011 => 4
        }

        @search = Evoasm::Search.new :x64 do |p|
          p.instructions = instruction_names
          p.kernel_size = 1
          p.program_size = 1
          p.population_size = 1600
          p.parameters = %i(reg0 reg1 reg2 reg3)

          p.examples = @examples
        end

        yield @search if block_given?

        @search.start! do |program, loss|
          if loss == 0.0
            @found_program = program
          end
          @found_program.nil?
        end
      end
    end

    @context = Context.new

    def test_program_size
      assert_equal 1, found_program.size
    end

    def test_program_run
      p examples
      # should generalize (i.e. give correct answer for non-training data)
      assert_equal 2, found_program.start(0b1001)
      assert_equal 3, found_program.start(0b1101)
    end
  end
end
