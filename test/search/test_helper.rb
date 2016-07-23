require_relative '../test_helper'

require 'evoasm'
require 'evoasm/search'
require 'evoasm/x64'
require 'tmpdir'

class SearchTest < Minitest::Test
  @@examples = nil
  @@found_adf = nil

  def test_search
    refute_nil @@found_adf, "no solution found"
    assert_kind_of Evoasm::ADF, @@found_adf
  end

  def test_adf_size
    assert_equal 1, @@found_adf.size
  end

  def test_adf_run_all
    assert_equal @@examples.values, @@found_adf.run_all(*@@examples.keys)
  end

  def test_adf_to_gv
    filename = Dir::Tmpname.create(['evoasm_gv_test', '.png']) {}
    @@found_adf.to_gv.save(filename)
    assert File.exist?(filename)
  end
end
