require 'evoasm/deme'
require 'evoasm/domain'

module Evoasm
  class Deme
    class Parameters < FFI::AutoPointer

      def initialize(ptr)
        super(ptr)

        self.seed = PRNG::DEFAULT_SEED
      end

      def mutation_rate
        Libevoasm.deme_params_mut_rate(self)
      end

      def mutation_rate=(mutation_rate)
        Libevoasm.deme_params_set_mut_rate self, mutation_rate
      end

      def size
        Libevoasm.deme_params_size self
      end

      def size=(size)
        Libevoasm.deme_params_set_size self, size
      end

      def parameters=(parameter_names)
        parameter_names.each_with_index do |parameter_name, index|
          Libevoasm.deme_params_set_param(self, index, parameters_enum_type[parameter_name])
        end
        Libevoasm.deme_params_set_n_params(self, parameter_names.size)
      end

      def parameters
        Array.new(Libevoasm.deme_params_n_params self) do |index|
          parameters_enum_type[Libevoasm.deme_params_param(self, index)]
        end
      end

      def domains=(domains_hash)
        domains = []
        domains_hash.each do |parameter_name, domain_value|
          domain = Domain.for domain_value
          success = Libevoasm.deme_params_set_domain(self, parameter_name, domain)
          if !success
            raise ArgumentError, "no such parameter #{parameter_name}"
          end
          domains << domain
        end

        # keep reference to prevent disposal by GC
        @domains = domains
      end

      def domains
        parameters.map do |parameter_name|
          domain_ptr = Libevoasm.deme_params_domain(self, parameter_name)
          domain = @domains.find {|domain| domain == domain_ptr}
          [parameter_name, domain]
        end.to_h
      end

      def seed=(seed)
        if seed.size != PRNG::SEED_SIZE
          raise ArgumentError, 'invalid seed size'
        end

        seed.each_with_index do |seed_value, index|
          Libevoasm.deme_params_set_seed(self, index, seed_value)
        end
      end

      def seed
        Array.new(PRNG::SEED_SIZE) do |index|
          Libevoasm.deme_params_seed(self, index)
        end
      end

      def validate!
        unless Libevoasm.deme_params_valid(self)
          raise Error.last
        end
      end
    end
  end
end
