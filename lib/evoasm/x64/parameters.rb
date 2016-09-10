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

      def self.for(parameters, basic: false)
        case parameters
        when self
          if basic && !parameters.basic?
            raise ArgumentError, 'cannot convert non-basic parameters '\
                                 'to basic parameters'
          end
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
          if basic
            Libevoasm.enum_type(:x64_basic_param_id)
          else
            Libevoasm.enum_type(:x64_param_id)
          end

        @basic = basic
        @disp_size_enum_type = Libevoasm.enum_type :x64_disp_size
        @addr_size_enum_type = Libevoasm.enum_type :x64_addr_size
        @scale_enum_type = Libevoasm.enum_type :x64_scale

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
        converted_value = convert_value parameter_name, value
        parameter_id = parameter_name_to_id(parameter_name)

        if basic?
          Libevoasm.x64_basic_params_set self, parameter_id, converted_value
        else
          Libevoasm.x64_params_set self, parameter_id, converted_value
        end
      end

      private

      def convert_value(parameter_name, value)
        raise ArgumentError, 'value cannot be nil' if value.nil?
        return 1 if value == true
        return 0 if value == false

        case parameter_name
        when :disp_size
          convert_displacement value
        when :addr_size
          convert_address_size value
        when :scale
          convert_scale value
        else
          value
        end
      end

      def convert_displacement(value)
        symbol =
          case value
          when 8
            :disp8
          when 32
            :disp32
          else
            raise ArgumentError, "invalid displacement '#{value}'"
          end

        @disp_size_enum_type[symbol]
      end

      def convert_address_size(value)
        symbol =
          case value
          when 32
            :addr_size32
          when 64
            :addr_size64
          else
            raise ArgumentError, "invalid address size '#{value}'"
          end

        @addr_size_enum_type[symbol]
      end

      def convert_scale(value)
        symbol =
          case value
          when 1
            :scale1
          when 2
            :scale2
          when 4
            :scale4
          when 8
            :scale8
          else
            raise ArgumentError, "invalid scale '#{value}'"
          end

        @scale_enum_type[symbol]
      end

      def parameter_name_to_id(symbol)
        id = @param_id_enum_type[symbol]

        if id.nil?
          raise ArgumentError, "unknown parameter '#{symbol}'"
        end

        id
      end
    end
  end
end
