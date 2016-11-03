require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

Evoasm.min_log_level = :info

module Search
  class GCDTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)

      @examples = {
        [5, 1] => 1,
        [15, 5] => 5,
        [8, 2] => 2,
        [8, 4] => 4,
        [8, 6] => 2,
        [16, 8] => 8
      }

      @kernel_size = (20..50)
      @program_size = 5
      #@deme_size = 5000
      #@mutation_rate = 0.2
      @parameters = %i(reg0 reg1 reg2 reg3)
      start
    end

    def test_program_run
      # should generalize (i.e. give correct answer for non-training data)
    end
  end
end
