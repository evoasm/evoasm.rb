require 'evoasm/test'

require 'evoasm/island_model/parameters'

module Evoasm
  class IslandModel
    class ParametersTest < Minitest::Test
      def setup
        @parameters = Parameters.new
      end
    end
  end
end
