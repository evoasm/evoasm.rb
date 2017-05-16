require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

Evoasm.log_level = :info

module Evoasm
  class I64VectorTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:xmm)
      @examples = {
        [:i32x2, :i32x2] => :i32x2,
        [[0, 0], [1, 1]] => [[1, 1]],
        [[1, 2], [1, 1]] => [[2, 3]],
        [[5, 1], [2, 3]] => [[7, 4]],
      }

      @verification_examples = {
        [[3, 0], [1, 4]] => [[4, 4]]
      }

      @kernel_size = 1
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
