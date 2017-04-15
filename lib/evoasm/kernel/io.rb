require 'evoasm/kernel'

module Evoasm
  class Kernel
    # Represents one or multiple input/output tuples.
    class IO < FFI::AutoPointer

      # Maximum arity for tuples
      MAX_ARITY = 8

      include Enumerable

      # @!visibility private
      def self.release(ptr)
        Libevoasm.kernel_io_free(ptr)
      end

      # @param tuples [Array] array of input or output tuples
      def initialize(tuples)
        if tuples.is_a?(FFI::Pointer)
          super(tuples)
        else
          arity, types = determine_arity_and_types tuples

          if arity > MAX_ARITY
            raise ArgumentError, "maximum arity exceeded (#{arity} > #{MAX_ARITY})"
          end

          kernel_io_val_type_enum_type = Libevoasm.enum_type :kernel_io_val_type
          types_array = FFI::MemoryPointer.new :int, arity
          ffi_types = types.map {|t| kernel_io_val_type_enum_type[t]}
          types_array.write_array_of :int, ffi_types

          ptr = Libevoasm.kernel_io_alloc
          Libevoasm.kernel_io_init ptr, arity, tuples.size, types_array

          super(ptr)

          load! tuples, arity, types
        end
      end

      # @return [Integer] arity of tuples
      def arity
        Libevoasm.kernel_io_get_arity self
      end

      # @yield [Array] tuple
      def each
        return enum_for(:each) unless block_given?
        size.times do |tuple_index|
          yield self[tuple_index]
        end
      end

      # Converts to array of tuples
      def to_a
        Array.new(size) do |tuple_index|
          self[tuple_index]
        end
      end

      # @return [Integer] the number of input/output values
      def length
        Libevoasm.kernel_io_get_n_vals self
      end

      # @return [Integer] the number of input/output tuples
      def size
        Libevoasm.kernel_io_get_n_tuples self
      end

      # @param tuple_index [Integer]
      # @return [Array] returns the tuple at tuple_index
      def [](tuple_index)
        Array.new(arity) do |value_index|
          read_write_value(tuple_index, value_index)
        end
      end

      private

      def load!(tuples, arity, types)
        tuples.each_with_index do |tuple, tuple_index|
          Array(tuple).each_with_index do |value, value_index|
            read_write_value tuple_index, value_index, value
          end
        end
      end

      def read_write_value(tuple_index, value_index, value = nil)
        type = Libevoasm.kernel_io_get_type self, value_index
        len = Libevoasm.kernel_io_val_type_get_len type
        elem_type = Libevoasm.kernel_io_val_type_get_elem_type type

        ffi_type =
          case elem_type
          when :i64x1
            :int64
          when :u64x1
            :uint64
          when :i32x1
            :int32
          when :u32x1
            :uint32
          when :i16x1
            :int16
          when :u16x1
            :uint16
          when :f64x1
            :double
          when :f32x1
            :float
          else
            raise "unknown value type #{type}"
          end

        val_ptr = Libevoasm.kernel_io_get_val self, tuple_index, value_index

        if value
          value = Array(value)
          val_ptr.write_array_of ffi_type, value
          nil
        else
          value = val_ptr.read_array_of ffi_type, len
          if len == 1
            value.first
          else
            value
          end
        end
      end

      def tuple_types(tuple)
        Array(tuple).map do |value|
          value_type value
        end
      end

      def element_value_type(value, size)
        case value
        when Float
          :"f64x#{size}"
        when Integer
          :"i64x#{size}"
        end
      end

      def value_type(value)
        value_type =
          case value
          when Array
            types = value.map(&:class).uniq
            unless types.size == 1
              raise ArgumentError, "invalid mixed type vector value #{value}"
            end
            element_value_type value.first, value.size
          else
            element_value_type value, 1
          end

        value_type or
          raise ArgumentError, "invalid tuple value '#{value}' of type '#{value.class}'"
      end

      def determine_arity_and_types(tuples)
        arity = nil
        types = nil

        tuples.each do |tuple|
          tuple_arity = Array(tuple).size
          tuple_types = tuple_types tuple

          if arity && arity != tuple_arity
            raise ArgumentError,
                  "invalid arity for tuple '#{tuple}' (#{tuple_arity} for #{arity})"
          end

          if types && types != tuple_types
            raise ArgumentError,
                  "invalid types for tuple '#{tuple}' (#{tuple_types} for #{types})"
          end

          arity = tuple_arity
          types = tuple_types
        end

        [arity || 0, types || []]
      end
    end

    # Represents a kernel's input
    class Input < IO
    end

    # Represents a kernel's output
    class Output < IO
    end
  end
end