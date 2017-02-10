require 'evoasm'
require 'evoasm/x64'
require 'tmpdir'
require 'pp'
require 'json'

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
    @recur_limit = 0
    @deme_count = 1
  end

  def new_population(architecture = :x64)
    parameters = Evoasm::Population::Parameters.new architecture do |p|
      p.instructions = @instruction_names
      p.kernel_size = @kernel_size
      p.topology_size = @topology_size
      p.deme_size = @deme_size
      p.deme_count = @deme_count
      p.examples = @examples
      p.parameters = @parameters
      p.domains = @domains if @domains
      p.seed = @seed if @seed
      p.recur_limit = @recur_limit
    end

    Evoasm::Population.new parameters
  end

  def start(loss = 0.0, min_generations: 0, max_generations: 1024, &block)
    @population = new_population
    @found_program = nil

    @found_program, loss = @population.run(loss: loss, min_generations: min_generations, max_generations: max_generations) do |population, generation|
      best_loss = @population.best_loss
      if best_loss == Float::INFINITY
        @population.seed
      end

      if block
        block[@population]
      end

      if generation % 10
        @population.plot
      end

    end
  end

  module Tests
    def found_program
      @found_program
    end

    def test_intron_elimination
      assert_runs_examples found_program
      intron_eliminated_program = found_program.eliminate_introns
      assert_runs_examples intron_eliminated_program

      # FIXME: possible, no ?
      refute_equal intron_eliminated_program, found_program

      # found_program.to_gv.save '/tmp/orig.png'
      # program.to_gv.save '/tmp/intron.png'

      found_program.size.times do |index|
        assert_operator found_program.kernel_size(index), :>=, intron_eliminated_program.kernel_size(index)
      end

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

      5.times do
        @seed = Array.new(Evoasm::PRNG::SEED_SIZE) { rand(10000) }

        run_summaries = []

        run_count = 3
        run_count.times do
          random_code
          summaries = []

          start(0.5, min_generations: 10, max_generations: 20) do |population|
            summary = population.summary
            summaries << summary
          end

          run_summaries << summaries
        end

        assert_equal run_count, run_summaries.size

        run_summaries.each_with_index do |s, i|
          File.write("/tmp/t#{i}.txt", s.pretty_inspect)
        end

        run_summaries.uniq.tap do |uniq|
          assert_equal [run_summaries.first], uniq
        end
      end
    end
  end
end
