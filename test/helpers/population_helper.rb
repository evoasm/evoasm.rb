require 'evoasm'
require 'evoasm/x64'
require 'tmpdir'

module PopulationHelper
  class SearchContext
    attr_reader :search
    attr_reader :examples
    attr_reader :found_program

    def free
      search.free
    end
  end

  def set_deme_parameters_ivars
    @examples = {
      1 => 2,
      2 => 3,
      3 => 4
    }
    @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
    @kernel_size = (1..15)
    @kernel_count = 1
    @size = 1600
    @parameters = %i(reg0 reg1 reg2 reg3)
  end

  def new_populaiton
    Evoasm::Population.new :x64 do |p|
      p.instructions = @instruction_names
      p.kernel_size = @kernel_size
      p.kernel_count = @kernel_count
      p.size = @size
      p.parameters = @parameters
      p.examples = @examples
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
