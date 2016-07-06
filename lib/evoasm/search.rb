module Evoasm
  class Search
    module Util
      def flatten_examples(examples)
        arity = check_arity examples

        [examples.flatten, arity]
      end

      def check_arity(examples)
        arity = Array(examples.first).size
        examples.each do |example|
          example_arity = Array(example).size
          if arity && arity != example_arity
            raise ArgumentError, "invalid arity for example '#{example}'"\
                                " (#{example_arity} for #{arity})"
          end
        end
        arity
      end
    end

    DEFAULT_SEED = (1..64).to_a
    def initialize(arch, examples:, instructions:, kernel_size:,
                   program_size:, population_size:, parameters:,
                   mutation_rate: 0.10, seed: DEFAULT_SEED, domains: {}, recur_limit: 0)

      input_examples, output_examples = examples.keys, examples.values
      input_examples, input_arity = flatten_examples input_examples
      output_examples, output_arity = flatten_examples output_examples

      __initialize__ input_examples, input_arity, output_examples, output_arity,
                   arch, population_size, kernel_size, program_size, instructions,
                   parameters, mutation_rate, seed, domains, recur_limit
    end

    include Util

  end
end
