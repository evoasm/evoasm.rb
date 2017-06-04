require 'evoasm/ffi_ext'
require 'evoasm/prng'

module Evoasm
  # @!visibility private
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

  # @!visibility private
  class EnumerationDomain < Domain
    def self.new(*values)
      values = values.flatten.sort
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

  # @!visibility private
  class RangeDomain < Domain
    def self.new(min_or_type, max = nil)
      if max.nil?
        range_type = min_or_type
        min = 0
        max = 0
      else
        range_type = :custom
        min = min_or_type
        max = max
      end

      range_type_value = Libevoasm.enum_type(:range_domain_type).find range_type
      super(:range, [:int, range_type_value, :int64, min, :int64, max])
    end

    def type
      Libevoasm.range_domain_get_type self
    end
  end
end
