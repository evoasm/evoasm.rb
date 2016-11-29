require 'evoasm/test'
require 'evoasm/population'
require 'evoasm/prng'
require 'population_helper'

Evoasm.log_level = :warn
require 'pp'
module Search
  class GCDTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    SEED = Array.new(Evoasm::PRNG::SEED_SIZE) { rand(10000) }

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

      @seed = SEED
      @kernel_size = 20
      @program_size = 5
      @mutation_rate = 0.0
      @deme_count = 5
      @recur_limit = 100
      #@deme_size = 5000
      #@mutation_rate = 0.2
      @parameters = %i(reg0 reg1 reg2 reg3)

      unless self.name == 'test_consistent_progress'
        start
      end
    end

    make_my_diffs_pretty!

    def test_program_run
      # should generalize (i.e. give correct answer for non-training data)
      #assert_equal 2, found_program.run(16, 6)
      #assert_equal 1, found_program.run(15, 2)
    end
  end
end
