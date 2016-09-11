require 'evoasm/adf'

module Evoasm
  class ADF
    class IO < FFI::AutoPointer
      MAX_ARITY = 8

      include Enumerable

      def self.release(ptr)
        Libevoasm.adf_io_free(ptr)
      end

      def initialize(examples_or_ptr)
        if examples_or_ptr.is_a?(FFI::Pointer)
          super(examples_or_ptr)
        else
          examples = examples_or_ptr
          arity = determine_arity examples

          if arity > MAX_ARITY
            raise ArgumentError, "maximum arity exceeded (#{arity} > #{MAX_ARITY})"
          end

          flat_examples = examples.flatten

          ptr = Libevoasm.adf_io_alloc flat_examples.size
          load_examples ptr, flat_examples, arity

          super(ptr)
        end
      end

      def arity
        Libevoasm.adf_io_arity self
      end

      def each
        return enum_for(:each) unless block_given?
        size.times do |example_index|
          yield self[example_index]
        end
      end

      def to_a
        Array.new(size) do |example_index|
          self[example_index]
        end
      end

      def length
        Libevoasm.adf_io_len self
      end

      def size
        length / arity
      end

      def [](example_index)

        absolute_index = arity * example_index
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
        type = Libevoasm.adf_io_type self, index
        case type
        when :i64
          Libevoasm.adf_io_value_i64 self, index
        when :f64
          Libevoasm.adf_io_value_f64 self, index
        else
          raise
        end
      end

      def load_examples(ptr, flat_examples, arity)
        var_args = flat_examples.flat_map do |example_value|
          example_type, c_type = value_types example_value
          [:example_type, example_type, c_type, example_value]
        end

        success = Libevoasm.adf_io_init ptr, arity, *var_args

        unless success
          Libevoasm.adf_io_unref ptr
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
                "invalid example value '#{value}' of type '#{value.class}'"
        end
      end

      def determine_arity(examples)
        arity = nil
        examples.each do |example|
          example_arity = Array(example).size
          if arity && arity != example_arity
            raise ArgumentError,
                  "invalid arity for example '#{example}' (#{example_arity} for #{arity})"
          end
          arity = example_arity
        end
        arity || 0
      end
    end

    class Input < IO
    end

    class Output < IO
    end
  end
end