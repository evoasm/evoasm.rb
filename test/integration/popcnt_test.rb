require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

module Search
  class PopcntTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_population_parameters_ivars

      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
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
      @kernel_size = 1
      @program_size = 1
      @parameters = %i(reg0 reg1 reg2 reg3)

      start
    end


    def test_program_size
      assert_equal 1, found_program.size
    end

    def test_program_run
      p examples

      p found_program.run_all(*examples.keys)
      p @found_program.run_all(0b1001, 0, 0b1101)
      p found_program.run_all([0b1001], [0], [0b1101])
      p found_program.run_all([0b1001], [0], [0b1101])

      # should generalize (i.e. give correct answer for non-training data)
      assert_equal 2, found_program.run(0b1001)
      assert_equal 0, found_program.run(0b0)
      assert_equal 3, found_program.run(0b1101)
    end
  end
end
