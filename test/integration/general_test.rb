require_relative 'program_deme_helper'

module Search
  class GeneralTest < Minitest::Test

    def setup
      @examples = {
        1 => 2,
        2 => 3,
        3 => 4
      }
      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags, program_deme: true)
      @kernel_size = (1..15)
      @kernel_count = 1
      @size = 1600
      @parameters = %i(reg0 reg1 reg2 reg3)
    end

    def start
      @search = Evoasm::Search.new :x64 do |p|
        p.instructions = @instruction_names
        p.kernel_size = @kernel_size
        p.program_size = @kernel_count
        p.population_size = @size
        p.parameters = @parameters
        p.examples = @examples
      end

      @search.start! do |program, loss|
        if loss == 0.0
          @found_program = program
        end
        @found_program.nil?
      end
    end

    def test_no_error
      search!
    end

    def test_no_instructions
      @instruction_names = []
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_no_parameters
      @parameters = []
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_no_examples
      @examples = {}
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_zero_population_size
      @size = 0
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_invalid_program_size
      @kernel_count = 0
      assert_raises Evoasm::Error do
        search!
      end

      @kernel_count = (0..0)
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_invalid_kernel_size
      @kernel_size = 0
      assert_raises Evoasm::Error do
        search!
      end

      @kernel_size = (0..0)
      assert_raises Evoasm::Error do
        search!
      end
    end
  end
end
