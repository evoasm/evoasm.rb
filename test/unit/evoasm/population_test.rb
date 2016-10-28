require 'evoasm/test'
require 'evoasm/population'
require 'evoasm/x64'
require 'evoasm'


require 'population_helper'

module Evoasm
  class PopulationTest < Minitest::Test
    include PopulationHelper

    def setup
      set_deme_parameters_ivars
    end

    def start
      @deme = new_populaiton

      @deme.seed

      until @found_program
        @deme.evaluate do |program, loss|
          raise if loss != 0.0
          @found_program = program
        end
        @deme.next_generation!
      end
    end

    def test_unseeded
      error = assert_raises Evoasm::Error do
        deme = new_populaiton
        deme.evaluate { |_, _|}
      end

      assert_match /seed/, error.message
    end

    def test_no_error
      start
    end

    def test_no_instructions
      @instruction_names = []
      error = assert_raises Evoasm::Error do
        start
      end

      assert_match /instructions/, error.message
    end

    def test_no_parameters
      @parameters = []
      error = assert_raises Evoasm::Error do
        start
      end

      assert_match /parameters/, error.message
    end

    def test_no_examples
      @examples = {}
      error = assert_raises Evoasm::Error do
        start
      end

      assert_match /input|output/, error.message
    end

    def test_zero_size
      @size = 0
      error = assert_raises Evoasm::Error do
        start
      end

      assert_match /size/, error.message
    end

    def test_invalid_kernel_count
      @kernel_count = 0
      error = assert_raises Evoasm::Error do
        start
      end
      assert_match /count/, error.message

      @kernel_count = (0..0)
      error = assert_raises Evoasm::Error do
        start
      end
      assert_match /count/, error.message
    end

    def test_invalid_kernel_size
      @kernel_size = 0
      error = assert_raises Evoasm::Error do
        start
      end
      assert_match /size/, error.message

      @kernel_size = (0..0)
      error = assert_raises Evoasm::Error do
        start
      end
      assert_match /size/, error.message
    end
  end
end