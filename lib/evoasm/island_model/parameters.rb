require 'evoasm/deme'

module Evoasm
  class IslandModel
    class Parameters < FFI::AutoPointer
      def self.release(ptr)
        Libevoasm.island_model_params_free ptr
      end

      def initialize(architecture)
        ptr = Libevoasm.island_model_params_alloc
        Libevoasm.island_model_params_init ptr

        super(ptr)
      end
    end
  end
end
