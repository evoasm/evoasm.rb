require 'evoasm/test'

require 'evoasm/island_model/island/parameters'

module Evoasm
  class IslandModel
    class Island
      class ParametersTest < Minitest::Test
        def setup
          @parameters = Parameters.new
        end

        def test_emigration_rate
          @parameters.emigration_rate = 0.5
          assert_equal 0.5, @parameters.emigration_rate
        end

        def test_emigration_frequency
          @parameters.emigration_frequency = 100
          assert_equal 100, @parameters.emigration_frequency
        end

        def test_max_loss
          @parameters.max_loss = 0.10
          assert_equal 0.10, @parameters.max_loss
        end
      end
    end
  end
end

