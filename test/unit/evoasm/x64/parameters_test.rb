require 'evoasm/test'
require 'evoasm/x64/cpu_state'
require 'evoasm/buffer'

module Evoasm
  module X64
    class ParametersTest < Minitest::Test
      def setup
        @parameters = Parameters.new
        @basic_parameters = Parameters.new basic: true
      end

      def test_basic
        refute @parameters.basic?
        assert @basic_parameters.basic?
      end

      def test_register_parameter
        @parameters[:reg0] = :a
        assert_equal :a, @parameters[:reg0]

        @basic_parameters[:reg0] = :a
        assert_equal :a, @basic_parameters[:reg0]
      end

      def test_boolean_parameter
        @parameters[:force_long_vex?] = true
        assert_equal true, @parameters[:force_long_vex?]
      end

      def test_int_parameter
        @parameters[:disp] = 10
        assert_equal 10, @parameters[:disp]

        assert_raises ArgumentError do
          @parameters[:disp] = 10000000000000
        end
      end

      def test_scale_parameter
        @parameters[:scale] = 4
        assert_equal 4, @parameters[:scale]

        assert_raises ArgumentError do
          @parameters[:scale] = 5
        end
      end

      def test_addr_size_parameter
        @parameters[:addr_size] = 32
        assert_equal 32, @parameters[:addr_size]

        assert_raises ArgumentError do
          @parameters[:addr_size] = 2
        end
      end

      def test_invalid_parameter
        assert_raises do
          @parameters[:foo] = 42
        end
      end
    end
  end
end