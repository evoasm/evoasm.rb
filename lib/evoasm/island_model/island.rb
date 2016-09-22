require 'evoasm/island_model'

module Evoasm
  class IslandModel
    class Island < FFI::AutoPointer

      attr_reader :parameters

      def self.release(ptr)
        Libevoasm.island_free ptr
      end

      def initialize(island, deme, &block)
        @parameters = Parameters.new
        @deme = deme
        @island = island

        block[@parameters]

        ptr = Libevoasm.island_alloc
        unless Libevoasm.island_init ptr, @island, @deme, @parameters
          raise Error.last
        end

        super(ptr)
      end
    end
  end
end

require 'evoasm/island_model/island/parameters'
