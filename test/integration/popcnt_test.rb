require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

module Evoasm
  class PopcntTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

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

      @validation_examples = {
        0b1001 => 2,
        0b1000 => 1,
        0b1101 => 3
      }

      @kernel_size = 1
      @parameters = %i(reg0 reg1 reg2 reg3)
      @deme_size = @instruction_names.size
      start
    end
  end
end
