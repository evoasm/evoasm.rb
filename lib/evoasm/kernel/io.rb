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
          tuples = tuples
          arity = determine_arity tuples

          if arity > MAX_ARITY
            raise ArgumentError, "maximum arity exceeded (#{arity} > #{MAX_ARITY})"
          end

          flat_tuples = tuples.flatten

          ptr = Libevoasm.kernel_io_alloc flat_tuples.size
          load_tuples ptr, flat_tuples, arity

          super(ptr)
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
        Libevoasm.kernel_io_get_len self
      end

      # @return [Integer] the number of input/output pairs
      def size
        length / arity
      end

      # @param tuple_index [Integer]
      # @return [Array] returns the tuple at tuple_index
      def [](tuple_index)
        absolute_index = arity * tuple_index
        if arity > 1
          Array.new(arity) do |value_index|
            value_at(absolute_index + value_index)
          end
        else
          value_at(absolute_index)
        end
      end

      private

      def value_at(index)
        type = Libevoasm.kernel_io_get_type self, index
        case type
        when :i64
          Libevoasm.kernel_io_get_value_i64 self, index
        when :f64
          Libevoasm.kernel_io_get_value_f64 self, index
        else
          raise "unknown value type #{type}"
        end
      end

      def load_tuples(ptr, flat_tuples, arity)
        var_args = flat_tuples.flat_map do |tuple_value|
          tuple_type, c_type = value_types tuple_value
          [:io_val_type, tuple_type, c_type, tuple_value]
        end

        success = Libevoasm.kernel_io_init ptr, arity, *var_args

        unless success
          Libevoasm.kernel_io_unref ptr
          raise Error.last
        end
      end

      def value_types(value)
        case value
        when Float
          [:f64, :double]
        when Integer
          [:i64, :int64]
        else
          raise ArgumentError,
                "invalid tuple value '#{value}' of type '#{value.class}'"
        end
      end

      def determine_arity(tuples)
        arity = nil
        tuples.each do |tuple|
          tuple_arity = Array(tuple).size
          if arity && arity != tuple_arity
            raise ArgumentError,
                  "invalid arity for tuple '#{tuple}' (#{tuple_arity} for #{arity})"
          end
          arity = tuple_arity
        end
        arity || 0
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