require_relative '../test_helper'

require 'evoasm'
require 'evoasm/search'
require 'evoasm/x64'
require 'tmpdir'

module Search
  class SearchContext
    attr_reader :search
    attr_reader :examples
    attr_reader :found_adf

    def free
      search.free
    end
  end

  module SearchTests

    def context
      self.class.instance_variable_get :@context
    end

    def found_adf
      context.found_adf
    end

    def examples
      context.examples
    end

    def test_search
      refute_nil found_adf, "no solution found"
      assert_kind_of Evoasm::ADF, found_adf
    end

    def assert_runs_examples(adf)
      assert_equal examples.values, adf.run_all(*examples.keys)
    end

    def test_adf_to_gv
      filename = Dir::Tmpname.create(['evoasm_gv_test', '.png']) {}
      found_adf.to_gv.save(filename)
      assert File.exist?(filename)
    end

    def test_adf_run_all
      assert_runs_examples found_adf
    end

    def random_code
      ary = Array.new(10) { rand }
      ary.sort! if rand < 0.5
      ary.map! { |e| (e * rand(10_000)).to_i } if rand < 0.5
    end

    def test_consistent_progress
      all_progresses = []

      n = 5
      n.times do |i|
        random_code
        progresses = []
        context = self.class.const_get(:Context).new do |search|
          search.progress do |*args|
            progresses << args
          end
        end
        all_progresses << progresses
        context.free
      end

      assert_equal n, all_progresses.size

      all_progresses.uniq.tap do |uniq|
        assert_equal 1, uniq.size
      end
    end
  end
end
