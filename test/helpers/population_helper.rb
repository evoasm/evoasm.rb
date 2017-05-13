require 'evoasm'
require 'evoasm/x64'
require 'tmpdir'
require 'pp'
require 'json'

module PopulationHelper

  def set_default_parameters
    @validation_examples = {}
    @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
    @deme_size = 1024
    @parameters = %i(reg0 reg1 reg2 reg3)
    @deme_count = 2
  end

  def new_population(architecture = :x64)
    parameters = Evoasm::Population::Parameters.new architecture do |p|
      p.instructions = @instruction_names
      p.kernel_size = @kernel_size
      p.deme_size = @deme_size
      p.deme_count = @deme_count
      p.examples = @examples
      p.parameters = @parameters
      p.domains = @domains if @domains
      p.seed = @seed if @seed
      p.distance_metric = @distance_metric
      p.local_search_iteration_count = @local_search_iteration_count if @local_search_iteration_count
    end

    Evoasm::Population.new parameters
  end

  def start(loss = 0.0, min_generations: 0, max_generations: 1024, &block)
    @population = new_population
    @found_kernel = nil

    @found_kernel, loss = @population.run(loss: loss, min_generations: min_generations, max_generations: max_generations) do |population, generation|
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
    def found_kernel
      @found_kernel
    end

    def test_intron_elimination
      assert_runs_examples found_kernel
      intron_eliminated_kernel = found_kernel.eliminate_introns
      assert_runs_examples intron_eliminated_kernel

      # FIXME: possible, no ?
      refute_equal intron_eliminated_kernel, found_kernel

      assert_operator found_kernel.size, :>=, intron_eliminated_kernel.size

      puts intron_eliminated_kernel.disassemble format: true

    end

    def examples
      @examples
    end

    def test_kernel_found
      refute_nil found_kernel, "no solution found"
      assert_kind_of Evoasm::Kernel, found_kernel
      puts found_kernel.disassemble format: true
    end

    def assert_runs_examples(kernel)
      examples = @population.parameters.examples
      assert @examples.size - examples.size <= 1
      assert_equal examples.values, kernel.run_all(*examples.keys)
    end

    def test_kernel_run_all
      assert_runs_examples found_kernel
    end

    def test_validation_examples
      @validation_examples.each do |example|
        assert_equal example[1], found_kernel.run(*example[0])
      end
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

        # run_summaries.each_with_index do |s, i|
        #   File.write("/tmp/t#{i}.txt", s.pretty_inspect)
        # end

        run_summaries.uniq.tap do |uniq|
          assert_equal [run_summaries.first], uniq
        end
      end
    end
  end
end
