require 'evoasm/ffi_ext'
require 'evoasm/prng'

module Evoasm
  class Domain < FFI::AutoPointer
    class << self
      def release(ptr)
        Libevoasm.domain_free ptr
      end

      def wrap(ptr)
        type = Libevoasm.domain_get_type ptr
        case type
        when :enum
          EnumerationDomain.new_from_pointer ptr
        when :range
          RangeDomain.new_from_pointer ptr
        when :int8, :int16, :int32, :int64
          TypeDomain.new_from_pointer ptr
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

      alias new_from_pointer new

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

    def rand(prng = PRNG.default)
      Libevoasm.domain_rand self, prng
    end

    def bounds
      return nil if is_a?(EnumerationDomain)

      min = FFI::MemoryPointer.new :int64
      max = FFI::MemoryPointer.new :int64

      Libevoasm.domain_get_bounds self, min, max

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
      var_args = [:uint, values.size, *values.flat_map { |v| [:int64, v]}]
      super(:enum, var_args)
    end

    def length
      Libevoasm.enum_domain_get_len self
    end

    def values
      Array.new(length) do |index|
        Libevoasm.enum_domain_get_val self, index
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
      Libevoasm.domain_get_type self
    end
  end
end
