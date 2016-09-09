require 'evoasm/ffi_ext'

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
    typedef :uint8, :adf_size
    typedef :uint8, :kernel_size
    typedef :double, :loss
    typedef :uint64, :params_bitmap

    enum :domain_type, [
      :enum,
      :range,
      :int64,
      :int32,
      :int16,
      :int8
    ]

    enum :arch_id, [
      :x64
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

    enum FFI::Type::UINT8, :log_level, [
      :trace,
      :debug,
      :info,
      :warn,
      :error,
      :fatal,
      :n_log_levels
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

    def self.enum_hash_to_mem_ptr(hash, type, enum, n_key, bitmap: false, &block)
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

      array = FFI::MemoryPointer.new type, n, true

      if bitmap
        bitmap_ptr = FFI::MemoryPointer.new :uint64
        bitmap_ptr.put_uint64 0, enum_type.flags(keys, shift: true)
      end

      enum_type.values(keys).each_with_index do |enum_value, index|
        block[array[enum_value], values[index]]
      end

      if bitmap
        [array, bitmap_ptr]
      else
        array
      end
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

require 'evoasm/libevoasm/adf_io'
require 'evoasm/libevoasm/search_params'
require 'evoasm/libevoasm/x64_enums'
require 'evoasm/libevoasm/funcs'


