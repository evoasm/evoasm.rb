require 'ffi'

module Evoasm
  module Libevoasm
    extend FFI::Library

    ffi_lib File.join(Evoasm.ext_dir, 'evoasm_ext', FFI.map_library_name('evoasm'))

    enum :example_type, [
      :i64,
      :u64,
      :f64
    ]

    class ExampleValue < FFI::Union
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

    class Architecture
      MAX_PARAMS = 64
    end

    class Interval < FFI::Struct
      layout :type, :uint8,
             :min, :int64,
             :max, :int64
    end

    class Enumeration < FFI::Struct
      layout :type, :uint8,
             :len, :uint16,
             :vals, [:int64, 32]
    end

    class Domain < FFI::Struct
      layout :type, :uint8
    end

    class SearchParameters < FFI::Struct
      layout :insts, :pointer,
             :params, :pointer,
             :domains, [Domain.by_ref, Architecture::MAX_PARAMS],
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
             :seed32, [:uint32, 4]
    end

    enum FFI::Type::UINT16, :error_type, [
      :invalid,
      :argument,
      :memory,
      :arch,
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
    attach_evoasm_function :search_init, [:pointer, :pointer, SearchParameters.by_ref], :void
    attach_evoasm_function :search_destroy, [:pointer], :void
    callback :result_func, [:pointer, :loss, :pointer], :bool
    attach_evoasm_function :search_start, [:pointer, :loss, :result_func, :pointer], :void

    attach_evoasm_function :program_clone, [:pointer, :pointer], :bool
    attach_evoasm_function :program_destroy, [:pointer], :bool
    attach_evoasm_function :program_run, [:pointer, ProgramInput.by_ref, ProgramOutput.by_ref], :bool

    attach_evoasm_function :x64_alloc, [], :pointer
    attach_evoasm_function :x64_free, [:pointer], :void
    attach_evoasm_function :x64_init, [:pointer], :bool
    attach_evoasm_function :x64_destroy, [:pointer], :void

    attach_evoasm_function :arch_insts, [:pointer, :pointer], :uint16
    attach_evoasm_function :arch_enc, [:pointer, :inst_id, :pointer, :pointer], :bool
    attach_evoasm_function :arch_save2, [:pointer, :pointer], :size_t
  end
end

require 'evoasm/libevoasm/x64_enums'
