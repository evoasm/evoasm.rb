require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

Evoasm.log_level = :info

module Evoasm
  class SqrtTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:xmm).grep(/.*?sd/).grep_v /pack|mov|cvt|aes|cmp/ #.grep /(add|mul|sqrt).*?sd/
      @examples = {
        0.0 => 0.0,
        0.5 => 1.0606601717798212,
        1.0 => 1.7320508075688772,
        1.5 => 2.5248762345905194,
        2.0 => 3.4641016151377544,
        2.5 => 4.541475531146237,
        3.0 => 5.744562646538029,
        3.5 => 7.0622234459127675,
        4.0 => 8.48528137423857,
        4.5 => 10.00624804809475,
        5.0 => 11.61895003862225
      }

      @validation_examples = {
        10.0 => 31.937438845342623,
        11.0 => 36.78314831549904,
        12.0 => 41.8568990729127
      }

      @deme_size = 3000
      @kernel_size = 100
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
