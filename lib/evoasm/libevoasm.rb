require 'evoasm/core_ext/ffi'

module Evoasm
  module Libevoasm
    extend FFI::Library

    INT32_MAX = 0x7fffffff

    ffi_lib File.join(Evoasm.ext_dir, 'evoasm_ext', FFI.map_library_name('evoasm'))

    enum :example_type, [
      :i64,
      :u64,
      :f64
    ]

    typedef :uint16, :inst_id
    typedef :uint8, :program_size
    typedef :uint8, :kernel_size
    typedef :double, :loss
    typedef :uint64, :params_bitmap

    enum FFI::Type::UINT8, :domain_type, [
      :enum,
      :interval,
      :interval64
    ]

    enum FFI::Type::UINT16, :error_type, [
      :invalid,
      :argument,
      :memory,
      :arch,
    ]

    enum :x64_insts_flags, [
      :search, 1 << 0,
    ]

    class Arch
      MAX_PARAMS = 64
    end

    class ExampleVal < FFI::Union
      layout :i64, :int64,
             :u64, :uint64,
             :f64, :double
    end

    class Error < FFI::Struct
      layout :type, :error_type,
             :code, :uint16,
             :line, :uint32,
             :filename, [:char, 128],
             :msg, [:char, 128],
             :data, [:uint8, 64]
    end

    def self.attach_evoasm_function(name, args, ret)
      attach_function name, :"evoasm_#{name}", args, ret
    end

    def self.enum_hash_to_array(hash, enum, n_key, &block)
      enum_type =
        case enum
        when FFI::Enum
          enum
        else
          Libevoasm.enum_type(enum)
        end

      n = enum_type[n_key]
      keys = hash.keys
      values = hash.values

      bitmap = enum_type.flags(keys, shift: true)
      array = Array.new(n, 0)

      enum_type.values(keys).each_with_index do |enum_value, index|
        array[enum_value] = block[values[index]]
      end
      [array, bitmap, n]
    end

    class ParamVal
      def self.for(value)
        case value
        when Symbol
          enum_value = Libevoasm.enum_value value
          if enum_value.nil?
            raise ArgumentError, "unknown value '#{value}'"
          end
          enum_value
        when Numeric
          value
        when nil
          0
        when false
          0
        when true
          1
        else
          raise
        end
      end
    end


  end
end

require 'evoasm/libevoasm/domain'
require 'evoasm/libevoasm/adf_io'
require 'evoasm/libevoasm/search_params'
require 'evoasm/libevoasm/x64_enums'
require 'evoasm/libevoasm/funcs'


