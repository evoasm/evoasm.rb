require_relative '../test_helper'
require 'evoasm/search'
require 'evoasm/x64'
require 'tmpdir'

class SearchTest < Minitest::Test
  def test_search
    x64 = Evoasm::X64.new
    insts = x64.instructions(:xmm).grep /(add|mul|sqrt).*?sd/
    examples = {
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

    search = Evoasm::Search.new x64 do |p|
      p.instructions = insts
      p.kernel_size = (5..15)
      p.adf_size = 1
      p.population_size = 1600
      p.parameters = %i(reg0 reg1 reg2 reg3)

      regs = %i(xmm0 xmm1 xmm2 xmm3)
      p.domains = {
        reg0: regs,
        reg1: regs,
        reg2: regs,
        reg3: regs
      }

      p.examples = examples
    end

    found_adf = nil

    search.start! do |adf, loss|
      if loss == 0.0
        found_adf = adf
      end
      found_adf.nil?
    end

    refute_nil found_adf, "no solution found"
    assert_kind_of Evoasm::ADF, found_adf

    assert_equal examples.values, found_adf.run_all(*examples.keys)

    # should generalize (i.e. give correct answer for non-training data)
    assert_equal 31.937438845342623, found_adf.run(10.0)
    assert_equal 36.78314831549904, found_adf.run(11.0)
    assert_equal 41.8568990729127, found_adf.run(12.0)

    filename = Dir::Tmpname.create(['evoasm_gv_test', '.png']) {}
    found_adf.to_gv.save(filename)
    assert File.exist?(filename)
  end
end
