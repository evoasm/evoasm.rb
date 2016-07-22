require_relative 'test_helper'

class SymRegTest < SearchTest

  def self.setup
    x64 = Evoasm::X64.new
    insts = x64.instructions(:gp)
    @@examples = {
      [5, 1] => 1,
      [15, 5] => 5,
      [8, 2] => 2,
      [8, 4] => 4,
      [8, 6] => 2,
      [16, 8] => 8,
    }

    @@search = Evoasm::Search.new x64 do |p|
      p.instructions = insts
      p.kernel_size = (20..50)
      p.adf_size = 5
      p.population_size = 1600
      p.parameters = %i(reg0 reg1 reg2 reg3)
      p.examples = @@examples
    end

    @@search.start! do |adf, loss|
      if loss == 0.0
        @@found_adf = adf
      end
      @@found_adf.nil?
    end
  end

  setup
  def test_adf_run
    # should generalize (i.e. give correct answer for non-training data)
  end
end
