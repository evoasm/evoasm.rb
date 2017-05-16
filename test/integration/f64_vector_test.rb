require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

Evoasm.log_level = :info

module Evoasm
  class F64VectorTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:xmm)
      @examples = {
        [:f64x2, :f64x2] => :f64x2,
        [[0.0, 0.0], [1.0, 1.0]] => [1.0, 1.0],
        [[1.0, 2.0], [1.0, 1.0]] => [2.0, 3.0],
        [[0.5, 0.1], [0.2, 0.3]] => [0.7, 0.4],
      }

      @validation_examples = {
        [[3.0, 0.0], [0.4, 0.4]] => [3.4, 0.4]
      }

      @kernel_size = 1
      @deme_size = 3000
      @parameters = %i(reg0 reg1 reg2 reg3)
      #regs = %i(xmm0 xmm1 xmm2 xmm3)
      #@domains = {
      #  reg0: regs,
      #  reg1: regs,
      #  reg2: regs,
      #  reg3: regs
      #}

      start
    end
  end
end
