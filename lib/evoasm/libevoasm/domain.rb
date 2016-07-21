module Evoasm
  module Libevoasm
    class Interval < FFI::Struct
      layout :type, :domain_type,
             :min, :int64,
             :max, :int64

      def initialize
        super
        self[:type] = :interval
      end
    end

    class Enum < FFI::Struct
      MAX_SIZE = 16
      layout :type, :domain_type,
             :len, :uint16,
             :vals, [:int64, MAX_SIZE]

      def initialize
        super
        self[:type] = :enum
      end
    end

    class Domain < FFI::Struct
      layout :type, :uint8

      def self.for(domain)
        case domain
        when Range
          Libevoasm::Interval.new.tap do |interval|
            interval[:min] = domain.min
            interval[:max] = domain.max
          end
        when Array
          if domain.size > Libevoasm::Enum::MAX_SIZE
            raise ArgumentError, "enum exceeds maximum size"
          end
          Libevoasm::Enum.new.tap do |enum|
            enum[:len] = domain.size
            vals = domain.map do |value|
              Libevoasm::ParamVal.for value
            end
            enum[:vals].to_ptr.write_array_of_int64 vals
          end
        else
          raise ArgumentError, "domain must be range or array (have #{domain.class})"
        end
      end
    end
  end
end