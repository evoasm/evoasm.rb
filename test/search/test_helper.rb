require_relative '../test_helper'

require 'evoasm'
require 'evoasm/search'
require 'evoasm/x64'
require 'tmpdir'

module SearchTests
  @@examples = nil
  @@found_adf = nil

  def test_search
    refute_nil @@found_adf, "no solution found"
    assert_kind_of Evoasm::ADF, @@found_adf
  end

  def assert_runs_examples(adf)
    assert_equal @@examples.values, adf.run_all(*@@examples.keys)
  end

  def test_adf_to_gv
    filename = Dir::Tmpname.create(['evoasm_gv_test', '.png']) {}
    @@found_adf.to_gv.save(filename)
    assert File.exist?(filename)
  end

  def test_adf_run_all
    require 'pp'
    pp @@found_adf.disassemble true
    100.times do |i|
      p [i, @@examples.values == @@found_adf.run_all(*@@examples.keys)]
    end

    assert_runs_examples @@found_adf
  end
end
