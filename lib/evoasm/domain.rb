require 'evoasm/ffi_ext'

module Evoasm
  class Domain < FFI::AutoPointer
    class << self
      def release(ptr)
        Libevoasm.domain_free ptr
      end

      def wrap(ptr)
        type = Libevoasm.domain_type ptr
        case type
        when :enum
          EnumerationDomain.wrap_ ptr
        when :range
          RangeDomain.wrap_ ptr
        when :int8, :int16, :int32, :int64
          TypeDomain.wrap_ ptr
        else
          raise "invalid domain type #{type}"
        end
      end

      def for(value)
        case value
        when self
          value
        when Range
          RangeDomain.new value.min, value.max
        when Array
          EnumerationDomain.new *value
        else
          raise ArgumentError, "cannot convert into domain"
        end
      end

      protected

      alias wrap_ new

      def new(type, var_args)
        ptr = Libevoasm.domain_alloc
        success = Libevoasm.domain_init ptr, type, *var_args

        if success
          super(ptr)
        else
          Libevoasm.domain_free ptr
          raise Error.last
        end
      end
    end

    def bounds
      return nil if is_a?(EnumerationDomain)

      min = FFI::MemoryPointer.new :int64
      max = FFI::MemoryPointer.new :int64

      Libevoasm.domain_min_max self, min, max

      [min.read_int64, max.read_int64]
    end

    def min
      bounds[0]
    end

    def max
      bounds[1]
    end
  end

  class EnumerationDomain < Domain
    def self.new(*values)
      values = values.flatten
      values_ptr = FFI::MemoryPointer.new :int64, values.size
      values_ptr.write_array_of_int64 values

      super(:enum, [:uint, values.size, :pointer, values_ptr])
    end

    def length
      Libevoasm.enum_domain_len self
    end

    def values
      Array.new(length) do |index|
        Libevoasm.enum_domain_val self, index
      end
    end
  end

  class RangeDomain < Domain
    def self.new(min, max)
      super(:range, [:int64, min, :int64, max])
    end
  end

  class TypeDomain < Domain
    def self.new(type)
      super(type, [])
    end

    def type
      Libevoasm.domain_type self
    end
  end
end
