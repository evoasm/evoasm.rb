require 'evoasm/search'

module Evoasm
  class Program
    include Search::Util

    def run(*input_example)
      run_all(input_example).first
    end

    def run_all(*input_examples)
      input_examples, input_arity = flatten_examples input_examples
      p input_examples, input_arity
      __run__ input_examples, input_arity
    end

    def disassemble(*args)
      buffer.disassemble(*args)
    end
  end
end
