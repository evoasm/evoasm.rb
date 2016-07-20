module Evoasm
  class Search < FFI::AutoPointer
    attr_reader :architecture

    class Parameters
      ATTRS = %i(instructions kernel_size examples
                 program_size population_size parameters
                 mutation_rate seed32 seed64 domains recur_limit)

      attr_accessor *ATTRS

      def initialize
        @mutation_rate = 0.1
        @seed64 = (1..16).to_a
        @seed32 = (1..4).to_a
        @recur_limit = 100
        @domains = {}
      end

      def missing
        ATTRS.select do |attr|
          send(attr).nil?
        end
      end
    end

    module Util
      def convert_examples(examples)
        arity = determine_arity examples
        types = determine_types examples

        [examples.flatten, arity, types]
      end

      def determine_types(examples)
        types = nil
        examples.each do |example|
          example_types = example.map do |value|
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
        types
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
        arity
      end
    end

    def initialize(architecture, &block)
      @archictecture = architecture

      parameters = Parameters.new
      block[parameters]

      missing_parameters = parameters.missing
      unless missing_parameters.empty?
        raise ArgumentError, "missing parameters: #{missing_parameters.join ', '}"
      end

      ptr = Libevoasm.search_alloc
      Libevoasm.search_init ptr, architecture, convert_parameters(parameters)

      super(ptr)
    end

    def start!(&block)

      func = FFI::Function.new(:bool, [:pointer, :double, :pointer]) do |program, loss, _user_data|
        block[program, loss]
      end

      Libevoasm.search_start self, func, nil
    end

    def self.release(ptr)
      Libevoasm.search_destroy(ptr)
      Libevoasm.search_free(ptr)
    end

    include Util

    private
    def convert_domains(domains)
      domain_values, _, _ = Libevoasm.enum_hash_to_array(domains, :x64_param_id, :n_params) do |domain|
        case domain
        when Range
          Libevoasm::Interval.new.tap do |interval|
            interval[:min] = domain.min
            interval[:max] = domain.max
          end
        when Array
          if domain.size > Libevoasm::Enum::MAX_SIZE
            raise ArgumentError, "domain exceeds maximum size"
          end
          Libevoasm::Enum.new.tap do |enum|
            enum[:len] = domain.size
            vals = domain.map do |value|
              Libevoasm::map_parameter_value value
            end
            enum[:vals].to_ptr.write_array_of_int64 vals
          end
        else
          raise ArgumentError, "domain must be range or array (have #{domain.class})"
        end
      end
      domain_values
    end

    def convert_parameters(parameters)
      params = Libevoasm::SearchParams.new
      params.clear

      inst_id_enum =
        case @archictecture
        when X64
          Libevoasm.enum_type :x64_inst_id
        else
          raise
        end

      params[:mut_rate] = parameters.mutation_rate

      inst_array = FFI::MemoryPointer.new :uint16, parameters.instructions.size
      inst_array.write_array_of_uint16 inst_id_enum.values(parameters.instructions)
      params[:insts] = inst_array
      @inst_array = inst_array
      params[:insts_len] = parameters.instructions.size

      p @inst_array
      p parameters.instructions
      p inst_id_enum.values(parameters.instructions)

      %i(kernel_size program_size).each do |attr|
        size = parameters.send attr
        min_attr_name = :"min_#{attr}"
        max_attr_name = :"max_#{attr}"
        case size
        when Range
          params[min_attr_name] = size.min
          params[max_attr_name] = size.max
        when Integer
          params[min_attr_name] = size
          params[max_attr_name] = size
        else
          raise ArgumentError, "kernel size must be range or integer (have #{size.class})"
        end
      end

      params_ptr = FFI::MemoryPointer.new :uint8, parameters.parameters.size
      params_ptr.write_array_of_uint8 Libevoasm.enum_type(:x64_param_id).values parameters.parameters
      params[:params] =  params_ptr
      params[:params_len] = parameters.parameters.size

      params[:pop_size] = parameters.population_size
      params[:mut_rate] = (parameters.mutation_rate * Libevoasm::INT32_MAX).to_i
      params[:seed32].to_ptr.write_array_of_uint32 parameters.seed32
      params[:seed64].to_ptr.write_array_of_uint64 parameters.seed64
      params[:recur_limit] = parameters.recur_limit

      domains = convert_domains parameters.domains
      domains_ary = params[:domains]
      domains_ary.size.times do |i|
        domains_ary[i] = domains[i]
      end

      input_examples = parameters.examples.keys.map { |k| Array(k) }
      output_examples = parameters.examples.values.map { |k| Array(k) }

      input_examples, input_arity, input_types = convert_examples input_examples
      output_examples, output_arity, output_types = convert_examples output_examples

      example_type_enum_type = Libevoasm.enum_type :example_type

      program_output = Libevoasm::ProgramOutput.new
      program_output[:arity] = output_arity
      program_output[:len] = output_examples.size
      program_output[:types].to_ptr.write_array_of_int example_type_enum_type.values(output_types)

      program_input = Libevoasm::ProgramInput.new
      program_input[:arity] = input_arity
      program_input[:len] = input_examples.size
      program_input[:types].to_ptr.write_array_of_int example_type_enum_type.values(input_types)

      params[:program_input] = program_input
      params[:program_output] = program_output

      params
    end
  end
end
