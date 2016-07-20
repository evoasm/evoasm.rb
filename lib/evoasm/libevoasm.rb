require 'ffi'


class FFI::Enum
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
      self[key]
    end
  end
end

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

    class ExampleVal < FFI::Union
      layout :i64, :int64,
             :u64, :uint64,
             :f64, :double
    end

    class ProgramIO < FFI::Struct
      MAX_ARITY = 8
      layout :arity, :uint8,
             :len, :uint16,
             :vals, :pointer,
             :types, [:example_type, MAX_ARITY]
    end

    ProgramInput = ProgramIO
    ProgramOutput = ProgramIO

    typedef :uint16, :inst_id
    typedef :uint8, :program_size
    typedef :uint8, :kernel_size
    typedef :double, :loss
    typedef :uint64, :params_bitmap

    class Arch
      MAX_PARAMS = 64
    end

    enum FFI::Type::UINT8, :domain_type, [
      :enum,
      :interval,
      :interval64
    ]

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
    end

    class SearchParams < FFI::Struct
      layout :insts, :pointer,
             :params, :pointer,
             :domains, [:pointer, Arch::MAX_PARAMS],
             :min_program_size, :program_size,
             :max_program_size, :program_size,
             :min_kernel_size, :kernel_size,
             :max_kernel_size, :kernel_size,
             :recur_limit, :uint32,
             :insts_len, :uint16,
             :params_len, :uint8,
             :pop_size, :uint32,
             :mut_rate, :uint32,
             :program_input, ProgramInput,
             :program_output, ProgramOutput,
             :seed64, [:uint64, 16],
             :seed32, [:uint32, 4],
             :max_loss, :loss
    end

    enum FFI::Type::UINT16, :error_type, [
      :invalid,
      :argument,
      :memory,
      :arch,
    ]

    enum :x64_insts_flags, [
      :search, 1 << 0,
    ]

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

    attach_evoasm_function :init, [:int, :pointer, :pointer], :void
    attach_evoasm_function :last_error, [], Error.by_ref

    attach_evoasm_function :search_alloc, [], :pointer
    attach_evoasm_function :search_free, [:pointer], :void
    attach_evoasm_function :search_init, [:pointer, :pointer, SearchParams.by_ref], :void
    attach_evoasm_function :search_destroy, [:pointer], :void
    callback :result_func, [:pointer, :loss, :pointer], :bool
    attach_evoasm_function :search_start, [:pointer, :result_func, :pointer], :void

    attach_evoasm_function :program_clone, [:pointer, :pointer], :bool
    attach_evoasm_function :program_destroy, [:pointer], :bool
    attach_evoasm_function :program_run, [:pointer, ProgramInput.by_ref, ProgramOutput.by_ref], :bool

    attach_evoasm_function :arch_save2, [:pointer, :pointer], :size_t


    def self.enum_hash_to_array(hash, enum, n_key,&block)
      enum_type = Libevoasm.enum_type(enum)
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

    def self.map_parameter_value(value)
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

require 'evoasm/libevoasm/x64_enums'

module Evoasm
  module Libevoasm
    attach_evoasm_function :x64_alloc, [], :pointer
    attach_evoasm_function :x64_free, [:pointer], :void
    attach_evoasm_function :x64_init, [:pointer], :bool
    attach_evoasm_function :x64_destroy, [:pointer], :void
    attach_evoasm_function :x64_insts, [:pointer, :uint64, :uint64, :uint64, :uint64, :pointer], :uint16
    attach_evoasm_function :x64_enc, [:pointer, :x64_inst_id, :pointer, :pointer], :bool
    attach_evoasm_function :x64_features, [:pointer], :uint64
  end
end

