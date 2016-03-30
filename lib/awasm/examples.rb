module Awasm
  module Examples

    class << self
      def convert(examples)
        examples.inject(nil) do |(in_arity, out_arity), example|
          inputs, outputs = example
          example_in_arity = inputs.size
          example_out_arity = outputs.size

          validate_example inputs, example_in_arity, in_arity
          validate_example outputs, example_out_arity, out_arity

          [example_in_arity, example_out_arity]
        end.unshift(examples.flatten)
      end

      private
      def validate_example(example, example_arity, arity)
        if arity && arity != example_arity
          raise ArgumentError, "invalid arity for example '#{example}'"\
                                " (#{example_arity} for #{arity})"
        end
      end
    end
  end
end
