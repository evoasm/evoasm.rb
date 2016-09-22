require 'evoasm/island_model/island'

module Evoasm
  class IslandModel
    class Island
      class Parameters < FFI::AutoPointer
        def self.release(ptr)
          Libevoasm.island_params_free ptr
        end

        def initialize
          ptr = Libevoasm.island_params_alloc
          Libevoasm.island_params_init ptr

          super(ptr)
        end

        def emigration_rate=(emigration_rate)
          Libevoasm.island_params_set_emigr_rate(self, emigration_rate)
        end

        def emigration_rate
          Libevoasm.island_params_emigr_rate(self)
        end

        def emigration_frequency=(emigration_frequency)
          Libevoasm.island_params_set_emigr_freq(self, emigration_frequency)
        end

        def emigration_frequency
          Libevoasm.island_params_emigr_freq(self)
        end

        def max_loss=(max_loss)
          Libevoasm.island_params_set_max_loss(self, max_loss)
        end

        def max_loss
          Libevoasm.island_params_max_loss(self)
        end
      end
    end
  end
end