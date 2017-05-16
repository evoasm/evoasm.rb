module Evoasm
  module X64
    # Represents x86-64 instruction parameters.
    class Parameters < FFI::AutoPointer

      # @!visibility private
      def self.release(ptr)
        Libevoasm.x64_params_free ptr
      end

      # @!visibility private
      def self.for(parameters = {}, basic: false)
        case parameters
        when self
          if basic && !parameters.basic?
            raise ArgumentError, 'cannot convert non-basic parameters '\
                                 'to basic parameters'
          end
          parameters
        when Hash
          klass = basic ? BasicParameters : Parameters
          klass.new parameters
        else
          raise ArgumentError, "cannot convert #{parameters.class} into parameter"
        end
      end

      def inspect
        fields = @param_id_enum_type.symbols[0..-2].map {|s| "#{s}:#{self[s]}"}.join(' ')
        "#<#{self.class.inspect} #{fields}>"
      end

      def ==(other)
        return true if other.equal?(self)
        return false unless other.instance_of?(self.class)
        @param_id_enum_type.symbols[0..-2].all? do |s|
          self[s] == other[s]
        end
      end

      alias_method :eql?, :==

      # @param hash [Hash] a
      # @param basic [Bool] whether to use the basic encoder
      def initialize(hash = {})
        if basic?
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

          uint1: proc {|v| check_uint_range v, 1},
          int3: proc {|v| check_int_range v, 3},
          int4: proc {|v| check_int_range v, 4},
          int8: proc {|v| check_int_range v, 8},
          int32: proc {|v| check_int_range v, 32},
          int64: proc {|v| check_int_range v, 64},
          reg: proc {|v| @reg_id_enum_type[v]}
        }

        @inv_type_map = @type_map.map do |k, v|
          if v.is_a? Hash
            [k, v.invert]
          else
            [k, v]
          end
        end.to_h

        @inv_type_map[:reg] = proc {|v| v}

        super(ptr)

        hash.each do |k, v|
          self[k] = v
        end
      end

      # Returns whether this parameters are for basic encoding
      # @return [Bool]
      def basic?
        false
      end

      # Creates a random set of parameters for the given instruction
      # and parameters
      # @param [X64::Instruction, Array<X64::Instruction>] instruction
      # @return [X64::Parameters]
      def self.random(instruction, other_instruction = nil)
        parameters = Evoasm::X64::Parameters.new
        success =
          if other_instruction
            Libevoasm.x64_params_rand2 parameters, instruction, other_instruction, Evoasm::PRNG.default
          else
            Libevoasm.x64_params_rand parameters, instruction, Evoasm::PRNG.default
          end

        if success
          parameters
        else
          nil
        end
      end

      # @param parameter_name [Symbol] the parameter's name
      # @return [Symbol, Integer] the parameter value
      def [](parameter_name)
        ffi_value =
          if basic?
            Libevoasm.x64_basic_params_get self, parameter_name_to_id(parameter_name)
          else
            Libevoasm.x64_params_get self, parameter_name_to_id(parameter_name)
          end

        ffi_value_to_value parameter_name, ffi_value
      end

      # Checks the existence of a parameter
      # @param parameter_name [Symbol] the parameter name
      # @return [Bool] whether the parameter exists or nor
      def parameter?(parameter_name)
        !@param_id_enum_type[parameter_name].nil?
      end

      # Set a parameter
      # @param parameter_name [Symbol] the parameter's name
      # @param value [Symbol, Integer] the parameter's value
      # @return [void]
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

      def check_uint_range(value, bitsize)
        min = 0
        max = 2**bitsize - 1
        raise ArgumentError, "#{value} exceeds value range #{min}..#{max}" if value < min || value > max

        value
      end

      def check_int_range(value, bitsize)
        min = -2**bitsize
        max = -min - 1
        raise ArgumentError, "#{value} exceeds value range #{min}..#{max}" if value < min || value > max

        value
      end

      def parameter_type(parameter_name)
        if basic?
          Libevoasm.x64_basic_param_get_type(parameter_name)
        else
          Libevoasm.x64_param_get_type(parameter_name)
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

    class BasicParameters < Parameters
      # @!visibility private
      def self.release(ptr)
        Libevoasm.x64_basic_params_free ptr
      end

      def random
        raise NotImplementedError
      end

      def basic?
        return true
      end
    end

  end
end
