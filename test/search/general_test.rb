require_relative 'test_helper'

module Search
  class GeneralTest < Minitest::Test

    def setup
      @x64 = Evoasm::X64.new
      @examples = {
        1 => 2,
        2 => 3,
        3 => 4
      }
      @instructions = @x64.instructions(:gp, :rflags, search: true)
      @kernel_size = (1..15)
      @adf_size = 1
      @population_size = 1600
      @parameters = %i(reg0 reg1 reg2 reg3)
    end

    def search!
      @search = Evoasm::Search.new @x64 do |p|
        p.instructions = @instructions
        p.kernel_size = @kernel_size
        p.adf_size = @adf_size
        p.population_size = @population_size
        p.parameters = @parameters
        p.examples = @examples
      end

      @search.start! do |adf, loss|
        if loss == 0.0
          @found_adf = adf
        end
        @found_adf.nil?
      end
    end

    def test_no_error
      search!
    end

    def test_no_instructions
      @instructions = []
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_no_parameters
      @parameters = []
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_no_examples
      @examples = {}
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_zero_population_size
      @population_size = 0
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_invalid_adf_size
      @adf_size = 0
      assert_raises Evoasm::Error do
        search!
      end

      @adf_size = (0..0)
      assert_raises Evoasm::Error do
        search!
      end
    end

    def test_invalid_kernel_size
      @kernel_size = 0
      assert_raises Evoasm::Error do
        search!
      end

      @kernel_size = (0..0)
      assert_raises Evoasm::Error do
        search!
      end
    end
  end
end
