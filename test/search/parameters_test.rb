require_relative 'test_helper'
require 'evoasm/search/parameters'

module Search
  class ParametersTest < Minitest::Test
    def setup
      @parameters = Evoasm::Search::Parameters.new :x64
    end

    def test_kernel_size
      @parameters.kernel_size = 10
      assert_equal 10, @parameters.kernel_size
    end

    def test_adf_size
      @parameters.adf_size = 10
      assert_equal 10, @parameters.adf_size
    end

    def test_seed
      assert_equal Evoasm::Search::Parameters::DEFAULT_SEED,
                   @parameters.seed

      assert_raises ArgumentError do
        @parameters.seed = [1,2,3]
      end

      seed = (16...32).to_a
      @parameters.seed = seed
      assert_equal seed, @parameters.seed
    end

    def test_mutation_rate
      @parameters.mutation_rate = 0.001
      assert_in_epsilon 0.001, @parameters.mutation_rate, 0.0001

      @parameters.mutation_rate = 0.5
      assert_in_epsilon 0.5, @parameters.mutation_rate, 0.0001
    end

    def test_population_size
      @parameters.population_size = 100
      assert_equal 100, @parameters.population_size
    end

    def test_recur_limit
      @parameters.recur_limit = 1000
      assert_equal 1000, @parameters.recur_limit
    end

    def test_examples
      examples = {
        [0, 1] => [0],
        [1, 0] => [100],
        [3, 5] => [10000]
      }
      @parameters.examples = examples
      assert_equal examples, @parameters.examples
    end

    def test_parameters
      parameters = %i(reg0 reg1 reg2)
      @parameters.parameters = parameters
      assert_equal parameters, @parameters.parameters

      parameters = %i(does not exist)
      assert_raises do
        @parameters.parameters = parameters
      end
    end

    def test_domains
      domains = {
        reg0: [:a, :c, :b],
        reg1: [:r11, :r12, :r13]
      }

      #@parameters.domains = domains
    end

  end
end
