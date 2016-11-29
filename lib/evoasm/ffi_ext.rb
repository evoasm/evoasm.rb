require 'ffi'

# @!visibility private
module FFI
  class Enum
    def flags(flags, shift: false)
      flags.inject(0) do |acc, flag|
        flag_value = self[flag]
        raise ArgumentError, "unknown flag '#{flag}'" if flag_value.nil?
        flag_value = 1 << flag_value if shift
        acc | flag_value
      end
    end

    def values(keys)
      keys.map do |key|
        enum_value = self[key]
        raise ArgumentError, "unknown enum key '#{key}'" if enum_value.nil?
        enum_value
      end
    end

    def keys(values)
      values.map do |value|
        enum_key = self[value]
        raise ArgumentError, "unknown enum value '#{value}'" if enum_key.nil?
        enum_key
      end
    end
  end

  class AbstractMemory
    def read_size_t
      case FFI.find_type :size_t
      when FFI::Type::Builtin::ULONG_LONG
        read_ulong_long
      when FFI::Type::Builtin::ULONG
        read_ulong
      when FFI::Type::Builtin::UINT
        read_uint
      else
        raise
      end
    end
  end

  class Pointer
    def to_ptr
      self
    end
  end
end

