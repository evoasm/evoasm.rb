require 'evoasm'
require 'evoasm/x64'
require 'tmpdir'

module PopulationHelper

  def set_population_parameters_ivars
    @examples = {
      1 => 2,
      2 => 3,
      3 => 4
    }
    @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
    @kernel_size = (1..15)
    @program_size = 1
    @deme_size = 1200
    @parameters = %i(reg0 reg1 reg2 reg3)
  end

  def new_population(architecture = :x64)
    parameters = Evoasm::Population::Parameters.new architecture do |p|
      p.instructions = @instruction_names
      p.kernel_size = @kernel_size
      p.program_size = @program_size
      p.deme_size = @deme_size
      p.examples = @examples
      p.parameters = @parameters
    end

    #p [@instruction_names, @examples, @parameters]

    Evoasm::Population.new :x64, parameters
  end

  def start
    @population = new_population

    @population.seed

    until @found_program
      @population.evaluate

      if @population.best_loss == 0.0
        @found_program = @population.best_program
      end

      @population.next_generation!
    end
  end

  module Tests
    def found_program
      @found_program
    end

    def examples
      @examples
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
