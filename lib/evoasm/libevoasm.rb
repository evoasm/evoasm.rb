require 'evoasm/ffi_ext'

module Evoasm
  module Libevoasm
    extend FFI::Library

    require 'evoasm/libevoasm/x64_enums'

    INT32_MAX = 0x7fffffff

    ffi_lib File.join(Evoasm.ext_dir, 'evoasm_ext', FFI.map_library_name('evoasm'))

    enum :example_type, [
      :i64,
      :u64,
      :f64
    ]

    typedef :uint16, :inst_id
    typedef :uint8, :param_id
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

    enum :error_type, [
      :argument,
      :memory,
      :encoding,
    ]

    enum :error_code, [
      :missing_parameter,
      :not_encodable
    ]

    enum :x64_insts_flags, [
      :search, 1 << 0,
    ]

    enum :log_level, [
      :trace,
      :debug,
      :info,
      :warn,
      :error,
      :fatal,
      :n_log_levels
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
    attach_evoasm_function :set_min_log_level, [:log_level], :void

    attach_evoasm_function :search_alloc, [], :pointer
    attach_evoasm_function :search_free, [:pointer], :void
    attach_evoasm_function :search_init, [:pointer, :arch_id, :pointer], :bool
    attach_evoasm_function :search_destroy, [:pointer], :void
    attach_evoasm_function :search_start, [:pointer, :pointer, :pointer, :pointer], :void

    attach_evoasm_function :arch_info, [:arch_id], :pointer
    attach_evoasm_function :arch_info_features, [:pointer], :uint64

    attach_evoasm_function :buf_ref_alloc, [], :pointer
    attach_evoasm_function :buf_ref_init, [:pointer, :pointer, :pointer], :void
    attach_evoasm_function :buf_ref_free, [:pointer], :void

    attach_evoasm_function :x64_params_alloc, [], :pointer
    attach_evoasm_function :x64_params_free, [:pointer], :void
    attach_evoasm_function :x64_params_init, [:pointer], :void
    attach_evoasm_function :x64_params_set, [:pointer, :x64_param_id, :int64], :void
    attach_evoasm_function :x64_basic_params_set, [:pointer, :x64_param_id, :int64], :void
    attach_evoasm_function :x64_params_get, [:pointer, :x64_param_id], :int64
    attach_evoasm_function :x64_basic_params_get, [:pointer, :x64_param_id], :int64
    attach_evoasm_function :x64_basic_params_alloc, [], :pointer
    attach_evoasm_function :x64_basic_params_free, [:pointer], :void
    attach_evoasm_function :x64_basic_params_init, [:pointer], :void

    attach_evoasm_function :param_id, [:pointer], :int
    attach_evoasm_function :param_domain, [:pointer], :pointer

    attach_evoasm_function :x64_init, [], :bool
    attach_evoasm_function :x64_insts, [:uint64, :uint64, :uint64, :uint64, :pointer], :uint16

    attach_evoasm_function :x64_enc, [:x64_inst_id, :pointer, :pointer], :bool
    attach_evoasm_function :x64_enc_basic, [:x64_inst_id, :pointer, :pointer], :bool

    attach_evoasm_function :x64_inst, [:x64_inst_id], :pointer
    attach_evoasm_function :x64_inst_param, [:pointer, :uint], :pointer
    attach_evoasm_function :x64_inst_n_params, [:pointer], :uint
    attach_evoasm_function :x64_inst_operand, [:pointer, :uint], :pointer
    attach_evoasm_function :x64_inst_n_operands, [:pointer], :uint
    attach_evoasm_function :x64_inst_mnem, [:pointer], :string
    attach_evoasm_function :x64_inst_enc, [:pointer, :pointer, :pointer], :bool
    attach_evoasm_function :x64_inst_enc_basic, [:pointer, :pointer, :pointer], :bool
    attach_evoasm_function :x64_inst_basic, [:pointer], :bool

    attach_evoasm_function :x64_operand_param_idx, [:pointer], :uint
    attach_evoasm_function :x64_operand_read, [:pointer], :bool
    attach_evoasm_function :x64_operand_written, [:pointer], :bool
    attach_evoasm_function :x64_operand_implicit, [:pointer], :bool
    attach_evoasm_function :x64_operand_mnem, [:pointer], :bool
    attach_evoasm_function :x64_operand_type, [:pointer], :x64_operand_type
    attach_evoasm_function :x64_operand_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_reg_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_index_reg_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_mem_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_reg_type, [:pointer], :x64_reg_type
    attach_evoasm_function :x64_operand_reg_id, [:pointer], :x64_reg_id
    attach_evoasm_function :x64_operand_imm, [:pointer], :int8

    attach_evoasm_function :adf_clone, [:pointer, :pointer], :bool
    attach_evoasm_function :adf_destroy, [:pointer], :bool
    attach_evoasm_function :adf_io_destroy, [:pointer], :void
    attach_evoasm_function :adf_alloc, [], :pointer
    attach_evoasm_function :adf_free, [:pointer], :void
    attach_evoasm_function :adf_run, [:pointer, :pointer], :pointer

    attach_evoasm_function :adf_size, [:pointer], :adf_size
    attach_evoasm_function :adf_kernel_code, [:pointer, :uint, :pointer], :size_t
    attach_evoasm_function :adf_code, [:pointer, :bool, :pointer], :size_t
    attach_evoasm_function :adf_kernel_alt_succ, [:pointer, :uint], :uint
    attach_evoasm_function :adf_eliminate_introns, [:pointer], :bool
    attach_evoasm_function :adf_is_input_reg, [:pointer, :uint, :uint8], :bool
    attach_evoasm_function :adf_is_output_reg, [:pointer, :uint, :uint8], :bool

    attach_evoasm_function :adf_io_alloc, [:uint16], :pointer
    attach_evoasm_function :adf_io_free, [:pointer], :void
    attach_evoasm_function :adf_io_init, [:pointer, :uint16, :varargs], :bool
    attach_evoasm_function :adf_io_arity, [:pointer], :uint8
    attach_evoasm_function :adf_io_len, [:pointer], :uint16
    attach_evoasm_function :adf_io_value_f64, [:pointer, :uint], :double
    attach_evoasm_function :adf_io_value_i64, [:pointer, :uint], :int64
    attach_evoasm_function :adf_io_type, [:pointer, :uint], :example_type

    attach_evoasm_function :search_params_alloc, [], :pointer
    attach_evoasm_function :search_params_free, [:pointer], :void
    attach_evoasm_function :search_params_init, [:pointer], :void

    attach_evoasm_function :search_params_min_adf_size, [:pointer], :adf_size
    attach_evoasm_function :search_params_max_adf_size, [:pointer], :adf_size
    attach_evoasm_function :search_params_min_kernel_size, [:pointer], :kernel_size
    attach_evoasm_function :search_params_max_kernel_size, [:pointer], :kernel_size
    attach_evoasm_function :search_params_recur_limit, [:pointer], :uint32
    attach_evoasm_function :search_params_pop_size, [:pointer], :uint32
    attach_evoasm_function :search_params_mut_rate, [:pointer], :uint32
    attach_evoasm_function :search_params_adf_input, [:pointer], :pointer
    attach_evoasm_function :search_params_adf_output, [:pointer], :pointer
    attach_evoasm_function :search_params_max_loss, [:pointer], :loss
    attach_evoasm_function :search_params_n_insts, [:pointer], :uint16
    attach_evoasm_function :search_params_n_params, [:pointer], :uint8
    attach_evoasm_function :search_params_set_min_adf_size, [:pointer, :adf_size], :void
    attach_evoasm_function :search_params_set_max_adf_size, [:pointer, :adf_size], :void
    attach_evoasm_function :search_params_set_min_kernel_size, [:pointer, :kernel_size], :void
    attach_evoasm_function :search_params_set_max_kernel_size, [:pointer, :kernel_size], :void
    attach_evoasm_function :search_params_set_recur_limit, [:pointer, :uint32], :void
    attach_evoasm_function :search_params_set_pop_size, [:pointer, :uint32], :void
    attach_evoasm_function :search_params_set_mut_rate, [:pointer, :uint32], :void
    attach_evoasm_function :search_params_set_adf_input, [:pointer, :pointer], :void
    attach_evoasm_function :search_params_set_adf_output, [:pointer, :pointer], :void
    attach_evoasm_function :search_params_set_max_loss, [:pointer, :loss], :void
    attach_evoasm_function :search_params_set_n_insts, [:pointer, :uint16], :void
    attach_evoasm_function :search_params_set_n_params, [:pointer, :uint8], :void
    attach_evoasm_function :search_params_set_domain, [:pointer, :uint8, :pointer], :bool
    attach_evoasm_function :search_params_domain, [:pointer, :uint8], :pointer

    attach_evoasm_function :search_params_set_inst, [:pointer, :uint, :inst_id], :void
    attach_evoasm_function :search_params_inst, [:pointer, :uint], :inst_id
    attach_evoasm_function :search_params_set_param, [:pointer, :uint, :param_id], :void
    attach_evoasm_function :search_params_param, [:pointer, :uint], :param_id
    attach_evoasm_function :search_params_prng, [:pointer], :pointer
    attach_evoasm_function :search_params_set_prng, [:pointer, :pointer], :void
    attach_evoasm_function :search_params_valid, [:pointer], :bool

    attach_evoasm_function :prng_init, [:pointer, :varargs], :void
    attach_evoasm_function :prng_alloc, [], :pointer
    attach_evoasm_function :prng_free, [:pointer], :void
    attach_evoasm_function :prng_rand64, [:pointer], :uint64
    attach_evoasm_function :prng_rand32, [:pointer], :uint32
    attach_evoasm_function :prng_rand16, [:pointer], :uint16
    attach_evoasm_function :prng_rand8, [:pointer], :uint8
    attach_evoasm_function :prng_rand_between, [:pointer, :int64, :int64], :int64

    attach_evoasm_function :adf_io_alloc, [:uint16], :pointer
    attach_evoasm_function :adf_io_init, [:pointer, :uint16, :varargs], :bool

    attach_evoasm_function :enum_domain_len, [:pointer], :uint
    attach_evoasm_function :enum_domain_val, [:pointer, :uint], :int64
    attach_evoasm_function :domain_alloc, [], :pointer
    attach_evoasm_function :domain_free, [:pointer], :void
    attach_evoasm_function :domain_init, [:pointer, :domain_type, :varargs], :bool
    attach_evoasm_function :domain_min_max, [:pointer, :pointer, :pointer], :void
    attach_evoasm_function :domain_type, [:pointer], :domain_type

    attach_evoasm_function :error_type, [:pointer], :error_type
    attach_evoasm_function :error_code, [:pointer], :error_code
    attach_evoasm_function :error_line, [:pointer], :uint32
    attach_evoasm_function :error_msg, [:pointer], :string
    attach_evoasm_function :error_filename, [:pointer], :string
  end
end


