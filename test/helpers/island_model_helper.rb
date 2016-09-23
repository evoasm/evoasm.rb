require_relative 'helpers/program_deme_helper'

require 'evoasm'
require 'evoasm/program_deme'
require 'evoasm/x64'
require 'tmpdir'

module IslandModel
  class SearchContext
    attr_reader :search
    attr_reader :examples
    attr_reader :found_program

    def free
      search.free
    end
  end

  module SearchTests

    def context
      self.class.instance_variable_get :@context
    end

    def found_program
      context.found_program
    end

    def examples
      context.examples
    end

    def test_search
      refute_nil found_program, "no solution found"
      assert_kind_of Evoasm::Program, found_program
    end

    def assert_runs_examples(program)
      assert_equal examples.values, program.run_all(*examples.keys)
    end

    def test_program_to_gv
      filename = Dir::Tmpname.create(['evoasm_gv_test', '.png']) {}
      found_program.to_gv.save(filename)
      assert File.exist?(filename)
    end

    def test_program_run_all
      assert_runs_examples found_program
    end

    def random_code
      # Fill registers with random values

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
