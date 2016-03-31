require 'awasm/search'

module Awasm
  class Program
    include Search::Util

    def run(*input_example)
      run_all([input_example]).first
    end

    def run_all(*input_examples)
      input_examples, input_arity = flatten_examples input_examples
      __run__ input_examples, input_arity
    end
  end
end
