require_relative 'program_deme_helper'

module Search
  class GeneralTest < Minitest::Test

    def setup
      @examples = {
        1 => 2,
        2 => 3,
        3 => 4
      }
      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags, population: true)
      @kernel_size = (1..15)
      @program_size = 1
      @deme_size = 1600
      @parameters = %i(reg0 reg1 reg2 reg3)
    end

    def start
      @search = Evoasm::Search.new :x64 do |p|
        p.instructions = @instruction_names
        p.kernel_size = @kernel_size
        p.program_size = @kernel_count
        p.population_size = @size
        p.parameters = @parameters
        p.examples = @examples
      end

      @search.start! do |program, loss|
        if loss == 0.0
          @found_program = program
        end
        @found_program.nil?
      end
    end
  end
end
