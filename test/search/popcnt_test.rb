require_relative 'test_helper'

class SymRegTest < SearchTest

  def self.setup
    x64 = Evoasm::X64.new
    insts = x64.instructions(:gp)
    p insts
    @@examples = {
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

    @@search = Evoasm::Search.new x64 do |p|
      p.instructions = insts
      p.kernel_size = (5..15)
      p.adf_size = 1
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
    assert_equals 1, @@found_adf.run(0b1001)
  end
end
