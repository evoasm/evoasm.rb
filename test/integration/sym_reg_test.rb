require 'evoasm/test'
require 'evoasm/population'
require 'population_helper'

Evoasm.log_level = :info

module Evoasm
  class SymRegTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:xmm).grep(/.*?sd/).grep_v /pack|mov|cvt|aes|cmp/ #.grep /(add|mul|sqrt).*?sd/
      p @instruction_names
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

      @kernel_size = 100
      @deme_size = 3000
      @topology_size = 1
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

    def test_topology_size
      assert_equal 1, found_program.size
    end

    def test_program_run
      # should generalize (i.e. give correct answer for non-training data)
      p found_program.run_all(*@examples.keys)
      assert_equal 31.937438845342623, found_program.run(10.0)
      assert_equal 36.78314831549904, found_program.run(11.0)
      assert_equal 41.8568990729127, found_program.run(12.0)
    end
  end
end
