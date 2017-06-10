require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

Evoasm.log_level = :info

module Evoasm
  class AbsTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
      @examples = {
        [1] => 1,
        [-1] => 1,
        [2] => 2,
        [-2] => 2,
        [100] => 100,
        [-100] => 100,
        [-123456] => 123456,
        [123456] => 123456,
      }
      @kernel_size = 10
      @parameters = %i(reg0 reg1 reg2 reg3 imm0)
      #@domains = {
      #  imm0: [0b01010101, 0b11001100, 0b00001111, 0b10101010, 0b00110011, 0b11110000, 1, 2, 4]
      #}
      @deme_size = 512
      @distance_metric = :hamming
      @deme_count = 6
      start
    end
  end
end
