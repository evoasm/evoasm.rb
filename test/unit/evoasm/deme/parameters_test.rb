require 'evoasm/test'
require 'evoasm/deme/parameters'

module Evoasm
  class Deme
    module ParametersTest
      def test_mutation_rate
        @parameters.mutation_rate = 0.001
        assert_in_epsilon 0.001, @parameters.mutation_rate, 0.0001

        @parameters.mutation_rate = 0.5
        assert_in_epsilon 0.5, @parameters.mutation_rate, 0.0001
      end

      def test_size
        @parameters.size = 100
        assert_equal 100, @parameters.size
      end

      def test_validate!
        error = assert_raises Evoasm::Error do
          @parameters.validate!
        end

        # while at it, let's test Error
        assert_equal :argument, error.type
        assert_kind_of Integer, error.line
        assert_match /deme-params/, error.filename
      end
    end
  end
end
