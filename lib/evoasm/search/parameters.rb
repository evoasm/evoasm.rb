require 'evoasm/search'

module Evoasm
  class Search
    class Parameters < FFI::AutoPointer
      DEFAULT_SEED = (1..16).to_a
      SEED_SIZE = 16

      def self.release(ptr)
        Libevoasm.search_params_free ptr
      end

      attr_accessor :input, :output

      def initialize(architecture)
        ptr = Libevoasm.search_params_alloc
        Libevoasm.search_params_init ptr

        case architecture
        when :x64
          @inst_id_enum_type = Libevoasm.enum_type :x64_inst_id
          @param_id_enum_type = Libevoasm.enum_type :x64_param_id
        else
          raise "unknown architecture #{architecture}"
        end

        super(ptr)

        self.seed = DEFAULT_SEED
      end

      def instructions=(instructions)
        instructions.each_with_index do |instruction|
          name =
            if instruction.is_a? Symbol
              instruction
            else
              instruction.name
            end
          Libevoasm.search_params_set_inst(self, index, name)
        end
        Libevoasm.search_params_set_n_insts(self, instructions.size)
      end

      def instructions
        Array.new(Libevoasm.search_params_n_insts self) do |index|
          Libevoasm.search_params_inst(self, index)
        end
      end

      %w(kernel_size adf_size).each do |attr_name|
        define_method attr_name do
          min = Libevoasm.send "search_params_min_#{attr_name}", self
          max = Libevoasm.send "search_params_max_#{attr_name}", self

          if min == max
            return min
          else
            return (min..max)
          end
        end

        define_method "#{attr_name}=" do |value|
          case value
          when Range
            min = value.min
            max = value.max
          else
            min = value
            max = value
          end
          Libevoasm.send "search_params_set_min_#{attr_name}", self, min
          Libevoasm.send "search_params_set_max_#{attr_name}", self, max
        end
      end

      def mutation_rate
        Libevoasm.search_params_mut_rate(self) / Libevoasm::INT32_MAX.to_f
      end

      def mutation_rate=(mutation_rate)
        mutation_rate_i = (mutation_rate * Libevoasm::INT32_MAX).to_i
        Libevoasm.search_params_set_mut_rate self, mutation_rate_i
      end

      def population_size
        Libevoasm.search_params_pop_size self
      end

      def population_size=(population_size)
        Libevoasm.search_params_set_pop_size self, population_size
      end

      def recur_limit
        Libevoasm.search_params_recur_limit self
      end

      def recur_limit=(recur_limit)
        Libevoasm.search_params_set_recur_limit self, recur_limit
      end

      def examples=(examples)
        input_examples = examples.keys.map { |k| Array(k) }
        output_examples = examples.values.map { |k| Array(k) }

        self.input = ADF::Input.new input_examples
        self.output = ADF::Output.new output_examples
      end

      def examples
        input.zip(output).to_h
      end

      def parameters=(parameter_names)
        parameter_names.each_with_index do |parameter_name, index|
          Libevoasm.search_params_set_param(self, index, parameter_name)
        end

        Libevoasm.search_params_set_n_params(self, parameter_names.size)
      end

      def parameters
        Array.new(Libevoasm.search_params_n_params self) do |index|
          @param_id_enum_type[Libevoasm.search_params_param(self, index)]
        end
      end

      def domains=(domains_hash)
        domains_hash.each do |parameter_name, domain|
          Libevoasm.search_params_set_domain(self, parameter_name, Domain.for(domain))
        end
      end

      def domains
        parameters.map do |parameter_name|
          [parameter_name, Libevoasm.search_params_domain(self, parameter_name)]
        end.to_h
      end

      def seed=(seed)
        if seed.size != SEED_SIZE
          raise ArgumentError, "seed must be have exactly #{SEED_SIZE} elements"
        end
        seed_ptr = Libevoasm.search_params_seed(self)
        seed.each_with_index do |seed_value, index|
          Libevoasm.prng_seed_set(seed_ptr, index, seed_value)
        end
      end

      def seed
        seed_ptr = Libevoasm.search_params_seed(self)
        Array.new(SEED_SIZE) do |index|
          Libevoasm.prng_seed_get(seed_ptr, index)
        end
      end
    end
  end
end
