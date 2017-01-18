require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'


module Evoasm
  class BitwiseReverseTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
      @examples = {
        0b00000000 => 0b00000000,
        0b10000000 => 0b00000001,
        0b01000000 => 0b00000010,
        0b01100000 => 0b00000110,
        0b00010000 => 0b00001000,
        0b00001000 => 0b00010000,
        0b00000110 => 0b01100000,
      }
      @kernel_size = 30
      @topology_size = 2
      @deme_count = 2
      @parameters = %i(reg0 reg1 reg2 reg3)
      @mutation_rate = 0.5

      start
    end


    def test_topology_size
      assert_equal 1, found_program.size
    end

    def test_program_run
    end
  end
end
