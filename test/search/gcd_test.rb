require_relative 'test_helper'

Evoasm.min_log_level = :info

module Search
  class GCDTest < Minitest::Test
    include SearchTests


    class Context < SearchContext
      def initialize
        instruction_names = Evoasm::X64.instruction_names(:gp, :rflags, search: true)

        p instruction_names

        @examples = {
          [5, 1] => 1,
          [15, 5] => 5,
          [8, 2] => 2,
          [8, 2] => 2,
          [8, 4] => 4,
          [8, 6] => 2,
          [16, 8] => 8
        }

        @search = Evoasm::Search.new :x64 do |p|
          p.instructions = instruction_names
          p.kernel_size = (20..50)
          p.adf_size = 5
          p.population_size = 5000
          p.mutation_rate = 0.5
          p.parameters = %i(reg0 reg1 reg2 reg3)
          p.examples = @examples
        end

        yield @search if block_given?

        @search.start! do |adf, loss|
          if loss == 0.0
            @found_adf = adf
          end
          @found_adf.nil?
        end
      end
    end

    @context = Context.new

    def test_adf_run
      # should generalize (i.e. give correct answer for non-training data)
    end
  end
end
