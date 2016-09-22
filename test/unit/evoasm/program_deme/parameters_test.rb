require 'evoasm/test'
require 'evoasm/program_deme/parameters'
require 'evoasm/deme/parameters_test'

module Evoasm
  class ProgramDeme
    class ParametersTest < Minitest::Test

      include Deme::ParametersTest

      def setup
        @parameters = Evoasm::ProgramDeme::Parameters.new :x64
      end

      def test_kernel_size
        @parameters.kernel_size = 10
        assert_equal 10, @parameters.kernel_size

        @parameters.kernel_size = (0..100)
        assert_equal (0..100), @parameters.kernel_size
      end

      def test_kernel_count
        @parameters.kernel_count = 10
        assert_equal 10, @parameters.kernel_count

        @parameters.kernel_count = (0..100)
        assert_equal (0..100), @parameters.kernel_count
      end

      def test_recur_limit
        @parameters.recur_limit = 1000
        assert_equal 1000, @parameters.recur_limit
      end

      def test_examples
        examples = {
          [0, 1] => 0,
          [1, 0] => 100,
          [3, 5] => 10000
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
          reg1: [:r11, :r12, :r13],
          imm0: (0..10)
        }

        # must set parameter before setting domain
        assert_raises ArgumentError do
          @parameters.domains = domains
        end

        @parameters.parameters = %i(reg0 reg1 imm0)
        @parameters.domains = domains

        assert_kind_of Evoasm::EnumerationDomain, @parameters.domains[:reg0]
        assert_kind_of Evoasm::RangeDomain, @parameters.domains[:imm0]
        assert_equal 0, @parameters.domains[:imm0].min
        assert_equal 10, @parameters.domains[:imm0].max
      end

      def test_instructions
        instructions = %i(adc_al_imm8 adc_rm8_r8)
        @parameters.instructions = instructions

        assert_equal instructions, @parameters.instructions
      end
    end
  end
end
