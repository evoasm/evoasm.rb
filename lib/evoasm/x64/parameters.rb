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

      def inspect
        fields = @param_id_enum_type.symbols[0..-2].map { |s| "#{s}:#{self[s]}" }.join(' ')
        "#<#{self.class.inspect} #{fields}>"
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
        @reg_id_enum_type = Libevoasm.enum_type :x64_reg_id

        @disp_size_map = {
          8 =>  :disp8,
          32 => :disp32
        }
        @disp_size_inv_map = @disp_size_map.invert

        @addr_size_map = {
          32 => :addr_size32,
          64 => :addr_size64,
        }
        @addr_size_inv_map = @addr_size_map.invert

        @scale_map = {
          1 => :scale1,
          2 => :scale2,
          4 => :scale4,
          8 => :scale8
        }
        @scale_inv_map = @scale_map.invert

        super(ptr)

        hash.each do |k, v|
          self[k] = v
        end
      end

      def basic?
        @basic
      end

      def [](parameter_name)
        ffi_value =
          if basic?
            Libevoasm.x64_basic_params_get self, parameter_name_to_id(parameter_name)
          else
            Libevoasm.x64_params_get self, parameter_name_to_id(parameter_name)
          end

        ffi_value_to_value parameter_name, ffi_value
      end

      def parameter?(parameter_name)
        !@param_id_enum_type[parameter_name].nil?
      end

      def []=(parameter_name, value)
        ffi_value = value_to_ffi_value parameter_name, value
        parameter_id = parameter_name_to_id(parameter_name)

        if basic?
          Libevoasm.x64_basic_params_set self, parameter_id, ffi_value
        else
          Libevoasm.x64_params_set self, parameter_id, ffi_value
        end
      end

      private

      def value_to_ffi_value(parameter_name, parameter_value)
        raise ArgumentError, 'value cannot be nil' if parameter_value.nil?
        return 1 if parameter_value.equal? true
        return 0 if parameter_value.equal? false

        case parameter_name
        when :disp_size, :addr_size, :scale
          ffi_value = instance_variable_get(:"@#{parameter_name}_map")[parameter_value]

          if ffi_value.nil?
            raise ArgumentError, "#{parameter_value} is not valid for #{parameter_name}"
          end

          ffi_value
        when :reg0, :reg1, :reg2, :reg3, :reg_base, :reg_index
          @reg_id_enum_type[parameter_value]
        else
          parameter_value
        end
      end

      def ffi_value_to_value(parameter_name, ffi_value)
        case parameter_name
        when :disp_size, :addr_size, :scale
          enum_type = instance_variable_get(:"@#{parameter_name}_enum_type")
          symbol = enum_type[ffi_value]
          instance_variable_get(:"@#{parameter_name}_inv_map").fetch symbol
        when :reg0, :reg1, :reg2, :reg3, :reg_base, :reg_index
          @reg_id_enum_type[ffi_value]
        else
          ffi_value
        end
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
