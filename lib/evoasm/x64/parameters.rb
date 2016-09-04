module Evoasm
  module X64
    class Parameters < FFI::AutoPointer

      def self.release(ptr)
        if ptr.basic?
          Libevoasm.x64_basic_params_free ptr
        else
          Libevoasm.x64_params_free ptr
        end
      end

      def self.get(parameters, basic: false)
        case parameters
        when self
          parameters
        when Hash
          new parameters, basic: basic
        else
          raise ArgumentError, "cannot convert #{parameters.class} into parameter"
        end
      end

      def initialize(hash = {}, basic: false)
        if basic
          ptr = Libevoasm.x64_basic_params_alloc
          Libevoasm.x64_basic_params_init ptr
        else
          ptr = Libevoasm.x64_params_alloc
          Libevoasm.x64_params_init ptr
        end

        @param_id_enum_type =
          if basic?
            Libevoasm.enum_type(:x64_basic_param_id)
          else
            Libevoasm.enum_type(:x64_param_id)
          end

        super(ptr)

        hash.each do |k, v|
          self[k] = v
        end
      end

      def basic?
        @basic
      end

      def [](parameter_name)
        if basic?
          Libevoasm.x64_basic_params_get self, parameter_name_to_id(parameter_name)
        else
          Libevoasm.x64_params_get self, parameter_name_to_id(parameter_name)
        end
      end

      def []=(parameter_name, value)
        if basic?
          Libevoasm.x64_basic_params_set self,
                                         parameter_name_to_id(parameter_name), value
        else
          Libevoasm.x64_params_set self,
                                   parameter_name_to_id(parameter_name), value
        end
      end

      private

      def parameter_name_to_id(symbol)
        @param_id_enum_type[symbol]
      end
    end
  end
end
