module Evoasm
  module Libevoasm
    class ADFIO < FFI::Struct
      MAX_ARITY = 8
      layout :arity, :uint8,
             :len, :uint16,
             :vals, :pointer,
             :types, [:example_type, MAX_ARITY]

      def initialize(examples = nil)
        super()

        load_examples(examples) if examples
      end

      def to_a
        example_type_enum_type = Libevoasm.enum_type :example_type
        arity = self[:arity]
        len = self[:len]
        types = example_type_enum_type.keys(self[:types].to_ptr.read_array_of_int(arity))
        n_outputs = len / arity
        vals = FFI::Pointer.new ExampleVal, self[:vals]

        Array.new(n_outputs) do |index|
          type = types[index % arity]
          example_val = ExampleVal.new vals[index]
          example_val[type]
        end
      end

      private
      def load_examples(examples)
        arity = determine_arity examples
        types = determine_types examples

        if arity > ADFInput::MAX_ARITY
          raise ArgumentError, "maximum arity exceeded (#{arity} > #{ADFInput::MAX_ARITY})"
        end

        example_type_enum_type = Libevoasm.enum_type :example_type
        flat_examples = examples.flatten
        example_vals = FFI::MemoryPointer.new ExampleVal, flat_examples.size

        flat_examples.zip(types.cycle).each_with_index do |(example, type), index|
          example_val = ExampleVal.new example_vals[index]
          example_val[type] = example
        end

        self[:arity] = arity
        self[:len] = flat_examples.size
        self[:types].to_ptr.write_array_of_int example_type_enum_type.values(types)
        self[:vals] = example_vals
      end

      def determine_types(examples)
        types = nil
        examples.each do |example|
          example_types = Array(example).map do |value|
            case value
            when Float
              :f64
            when Integer
              :i64
            else
              raise ArgumentError,
                    "invalid example value '#{value}' of type '#{value.class}'"
            end
          end
          if types && example_types != types
            raise ArgumentError,
                  "invalid example types '#{example_types.inspect}' (expected '#{types.inspect}')"
          end
          types = example_types
        end
        types || []
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

    ADFOutput = ADFIO
    ADFInput = ADFIO
  end
end

