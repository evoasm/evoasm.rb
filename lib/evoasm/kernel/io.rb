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
      def initialize(tuples, types = nil)
        if tuples.is_a?(FFI::Pointer)
          super(tuples)
        else
          tuples = canonicalize_tuples tuples, types
          types = check_types tuples, types
          arity = types.size

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
        if arity > 1
          Array.new(arity) do |value_index|
            read_write_value(tuple_index, value_index)
          end
        else
          read_write_value(tuple_index, 0)
        end

      end

      private

      def canonicalize_tuples(tuples, types)
        vector_value = false

        if types && types.size == 1
          vector_size = Libevoasm.kernel_io_val_type_get_len types.first
          vector_value = vector_size > 1
        end

        tuples.map do |tuple|
          # each tuple should be an array
          # if it is a scalar or an array representing
          # a vector wrap in array
          tuple =
            case tuple
            when Array
              if vector_value && !tuple.first.is_a?(Array)
                [tuple]
              else
                tuple
              end
            else
              [tuple]
            end

          # each value should be an array
          # scalar values are handled like singleton vectors
          tuple = tuple.map do |value|
            Array(value)
          end
        end
      end

      def load!(tuples, arity, types)
        tuples.each_with_index do |tuple, tuple_index|
          tuple.each_with_index do |value, value_index|
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

      def check_tuple_type(tuple, types)
        tuple.zip(types.to_a).map do |value, type|
          check_value_type value, type
        end
      end

      def check_element_value_type(element_value, type)
        if type.nil?
          case element_value
          when Float
            :f64x1
          when Integer
            :i64x1
          else
            raise ArgumentError, "unknown value type #{element_value}"
          end
        else
          case type
          when :i8x1, :u8x1,
            :i16x1, :u16x1,
            :i32x1, :u32x1,
            :i64x1, :u64x1
            unless element_value.is_a? Integer
              raise ArgumentError, "#{element_value} is not an integer"
            end
          when :f32x1, :f64x1
            unless element_value.is_a? Float
              raise ArgumentError, "#{element_value} is not a floating-point number"
            end
          end
          type
        end
      end

      def check_value_type(value, type)
        if type
          element_type = Libevoasm.kernel_io_val_type_get_elem_type type
        end

        element_types = Array(value).map do |element_value|
          check_element_value_type element_value, element_type
        end

        unless element_types.uniq.size == 1
          raise ArgumentError, "invalid mixed type vector value #{value}"
        end

        Libevoasm.kernel_io_val_type_make element_types.first, element_types.size
      end

      def check_types(tuples, types)
        tuples.each do |tuple|
          types = check_tuple_type tuple, types
        end
        types
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