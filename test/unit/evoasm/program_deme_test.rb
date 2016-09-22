require 'evoasm/test'
require 'evoasm/program_deme'
require 'evoasm/x64'
require 'evoasm'

module Evoasm
  class ProgramDemeTest < Minitest::Test
    def setup
      @examples = {
        1 => 2,
        2 => 3,
        3 => 4
      }
      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
      @kernel_size = (1..15)
      @kernel_count = 1
      @size = 1600
      @parameters = %i(reg0 reg1 reg2 reg3)
    end

    def new_deme
      Evoasm::ProgramDeme.new :x64 do |p|
        p.instructions = @instruction_names
        p.kernel_size = @kernel_size
        p.kernel_count = @kernel_count
        p.size = @size
        p.parameters = @parameters
        p.examples = @examples
      end
    end

    def start
      @deme = new_deme

      p @deme.loss
      @deme.seed

      p @deme.loss
      Evoasm.min_log_level = :info
      puts
      puts

      until @found_program
        @deme.evaluate(0.0) do |program, loss|
          p loss
          if loss == 0.0
            @found_program = program
          end
          @found_program
        end
        p @deme.loss
        @deme.next_generation!
      end
    end

    def test_unseeded
      assert_raises Evoasm::Error do
        deme = new_deme
        deme.evaluate { |_, _| }
      end
    end

    def test_no_error
      start
    end

    def test_no_instructions
      @instruction_names = []
      assert_raises Evoasm::Error do
        start
      end
    end

    def test_no_parameters
      @parameters = []
      assert_raises Evoasm::Error do
        start
      end
    end

    def test_no_examples
      @examples = {}
      assert_raises Evoasm::Error do
        start
      end
    end

    def test_zero_population_size
      @size = 0
      assert_raises Evoasm::Error do
        start
      end
    end

    def test_invalid_program_size
      @kernel_count = 0
      assert_raises Evoasm::Error do
        start
      end

      @kernel_count = (0..0)
      assert_raises Evoasm::Error do
        start
      end
    end

    def test_invalid_kernel_size
      @kernel_size = 0
      assert_raises Evoasm::Error do
        start
      end

      @kernel_size = (0..0)
      assert_raises Evoasm::Error do
        start
      end
    end
  end
end