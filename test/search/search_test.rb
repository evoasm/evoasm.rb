require_relative '../test_helper'
require 'evoasm/cli'

class SearchTest < Minitest::Test
  def test_search

    x64 = Evoasm::X64.new
    search = Evoasm::Search.new x64 do |params|

    end

    search = Evoasm::Cli::Search.new File.join(Evoasm.examples_dir, 'sym_reg.yml'), %w()

    found_program = nil

    search.start! do |program, loss|
      if loss == 0.0
        found_program = program
      end

      found_program.nil?
    end

    refute_nil found_program, "no solution found"
  end
end
