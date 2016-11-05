require 'evoasm'
require 'evoasm/x64'
require 'tmpdir'

module PopulationHelper

  def set_default_parameters
    @examples = {
      1 => 2,
      2 => 3,
      3 => 4
    }
    @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
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
      p.domains = @domains if @domains
    end

    Evoasm::Population.new :x64, parameters
  end

  def start(&block)
    @population = new_population
    @found_program = nil
    @population.seed

    until @found_program
      @population.evaluate

      if block
        block[@population.summary]
      end

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

    def test_program_found
      refute_nil found_program, "no solution found"
      assert_kind_of Evoasm::Program, found_program
    end

    def assert_runs_examples(program)
      assert_equal examples.values, program.run_all(*examples.keys)
      p examples.keys
      p program.run_all(*examples.keys)
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
      all_summaries = []

      n = 5
      n.times do |i|
        random_code
        summaries = []

        start do |summary|
          summaries << summary
        end

        all_summaries << summaries
      end

      assert_equal n, all_summaries.size

      p all_summaries

      all_summaries.uniq.tap do |uniq|
        assert_equal [all_summaries.first], uniq
      end
    end
  end
end
