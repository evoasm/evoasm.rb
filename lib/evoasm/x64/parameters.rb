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

        @type_map_enum_types = {
          scale: @scale_enum_type,
          addr_size: @addr_size_enum_type,
          reg: @reg_id_enum_type
        }

        @type_map = {
          scale: {
            1 => :scale1,
            2 => :scale2,
            4 => :scale4,
            8 => :scale8
          },

          addr_size: {
            32 => :addr_size32,
            64 => :addr_size64,
          },

          bool: {
            true => 1,
            false => 0
          },

          int3: proc { |v| check_int_range v, 3 },
          int4: proc { |v| check_int_range v, 4 },
          int8: proc { |v| check_int_range v, 5 },
          int32: proc { |v| check_int_range v, 32 },
          int64: proc { |v| check_int_range v, 64 },
          reg: proc { |v| v }
        }

        @inv_type_map = @type_map.map do |k, v|
          if v.is_a? Hash
            [k, v.invert]
          else
            [k, v]
          end
        end.to_h

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

      def check_int_range(value, bitsize)
        min = -2**bitsize
        max = -min - 1
        raise ArgumentError, "#{value} exceeds value range #{min}..#{max}" if value < min || value > max

        value
      end

      def parameter_type(parameter_name)
        if basic?
          Libevoasm.x64_basic_params_get_type(parameter_name)
        else
          Libevoasm.x64_params_get_type(parameter_name)
        end
      end

      def value_to_ffi_value(parameter_name, parameter_value)
        raise ArgumentError, 'value cannot be nil' if parameter_value.nil?

        parameter_type = parameter_type parameter_name
        ffi_value = @type_map[parameter_type][parameter_value]

        if ffi_value.nil?
          raise ArgumentError, "value #{parameter_value} is invalid for #{parameter_name}"
        end

        ffi_value
      end

      def ffi_value_to_value(parameter_name, ffi_value)
        parameter_type = parameter_type parameter_name
        if @type_map_enum_types.key? parameter_type
          ffi_value = @type_map_enum_types[parameter_type][ffi_value]
        end
        @inv_type_map[parameter_type][ffi_value]
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
