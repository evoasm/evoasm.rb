require 'evoasm/test'

require 'evoasm/island_model'

module Evoasm
  class IslandModelTest < Minitest::Test

    def setup
      @island_model = IslandModel.new do |p|
      end

      @islands = Array.new 10 do
        IslandModel::Island.new @island_model, new_deme do |p|
          p.max_loss = 0.0
        end
      end

      @islands.each_cons()
    end

    def test_aa

    end
  end
end