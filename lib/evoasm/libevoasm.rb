require 'evoasm/ffi_ext'

module Evoasm
  module Libevoasm
    extend FFI::Library

    require 'evoasm/libevoasm/x64_enums'

    ffi_lib File.join(Evoasm.ext_dir, 'evoasm_ext', FFI.map_library_name('evoasm'))

    enum :example_type, [
      :i64,
      :u64,
      :f64
    ]

    typedef :uint16, :inst_id
    typedef :uint8, :param_id
    typedef :uint8, :kernel_count
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

    def self.attach_evoasm_function(name, args, returns, options = {})
      attach_function name, :"evoasm_#{name}", args, returns, options
    end

    attach_evoasm_function :init, [:int, :pointer, :pointer], :void
    attach_evoasm_function :get_last_error, [], Error.by_ref
    attach_evoasm_function :set_min_log_level, [:log_level], :void

    attach_evoasm_function :island_model_alloc, [], :pointer
    attach_evoasm_function :island_model_free, [:pointer], :void
    attach_evoasm_function :island_model_init, [:pointer, :pointer], :bool
    attach_evoasm_function :island_model_destroy, [:pointer], :void
    attach_evoasm_function :island_model_start,
                           [:pointer, :pointer, :pointer, :pointer], :void,
                           blocking: true

    attach_evoasm_function :get_arch_info, [:arch_id], :pointer
    attach_evoasm_function :arch_info_get_features, [:pointer], :uint64

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

    attach_evoasm_function :param_get_id, [:pointer], :int
    attach_evoasm_function :param_get_domain, [:pointer], :pointer

    attach_evoasm_function :x64_init, [], :bool
    attach_evoasm_function :x64_insts, [:uint64, :uint64, :uint64, :uint64, :pointer], :uint16

    attach_evoasm_function :x64_enc, [:x64_inst_id, :pointer, :pointer], :bool
    attach_evoasm_function :x64_enc_basic, [:x64_inst_id, :pointer, :pointer], :bool

    attach_evoasm_function :x64_inst, [:x64_inst_id], :pointer
    attach_evoasm_function :x64_inst_get_param, [:pointer, :uint], :pointer
    attach_evoasm_function :x64_inst_get_n_params, [:pointer], :uint
    attach_evoasm_function :x64_inst_get_operand, [:pointer, :uint], :pointer
    attach_evoasm_function :x64_inst_get_n_operands, [:pointer], :uint
    attach_evoasm_function :x64_inst_get_mnem, [:pointer], :string
    attach_evoasm_function :x64_inst_enc, [:pointer, :pointer, :pointer], :bool
    attach_evoasm_function :x64_inst_enc_basic, [:pointer, :pointer, :pointer], :bool
    attach_evoasm_function :x64_inst_is_basic, [:pointer], :bool

    attach_evoasm_function :x64_operand_get_param_idx, [:pointer], :uint
    attach_evoasm_function :x64_operand_is_read, [:pointer], :bool
    attach_evoasm_function :x64_operand_is_written, [:pointer], :bool
    attach_evoasm_function :x64_operand_is_implicit, [:pointer], :bool
    attach_evoasm_function :x64_operand_is_mnem, [:pointer], :bool
    attach_evoasm_function :x64_operand_get_type, [:pointer], :x64_operand_type
    attach_evoasm_function :x64_operand_get_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_reg_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_index_reg_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_mem_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_reg_type, [:pointer], :x64_reg_type
    attach_evoasm_function :x64_operand_get_reg_id, [:pointer], :x64_reg_id
    attach_evoasm_function :x64_operand_get_imm, [:pointer], :int8

    attach_evoasm_function :program_clone, [:pointer, :pointer], :bool
    attach_evoasm_function :program_destroy, [:pointer], :bool
    attach_evoasm_function :program_io_destroy, [:pointer], :void
    attach_evoasm_function :program_alloc, [], :pointer
    attach_evoasm_function :program_free, [:pointer], :void
    attach_evoasm_function :program_run, [:pointer, :pointer], :pointer

    attach_evoasm_function :program_get_kernel_count, [:pointer], :kernel_count
    attach_evoasm_function :program_get_kernel_code, [:pointer, :uint, :pointer], :size_t
    attach_evoasm_function :program_get_code, [:pointer, :bool, :pointer], :size_t
    attach_evoasm_function :program_get_kernel_alt_succ, [:pointer, :uint], :uint
    attach_evoasm_function :program_eliminate_introns, [:pointer], :bool
    attach_evoasm_function :program_is_input_reg, [:pointer, :uint, :uint8], :bool
    attach_evoasm_function :program_is_output_reg, [:pointer, :uint, :uint8], :bool

    attach_evoasm_function :program_io_alloc, [:uint16], :pointer
    attach_evoasm_function :program_io_free, [:pointer], :void
    attach_evoasm_function :program_io_init, [:pointer, :uint16, :varargs], :bool
    attach_evoasm_function :program_io_get_arity, [:pointer], :uint8
    attach_evoasm_function :program_io_get_len, [:pointer], :uint16
    attach_evoasm_function :program_io_get_value_f64, [:pointer, :uint], :double
    attach_evoasm_function :program_io_get_value_i64, [:pointer, :uint], :int64
    attach_evoasm_function :program_io_get_type, [:pointer, :uint], :example_type

    attach_evoasm_function :deme_params_get_size, [:pointer], :uint32
    attach_evoasm_function :deme_params_get_mut_rate, [:pointer], :double

    attach_evoasm_function :island_params_alloc, [], :pointer
    attach_evoasm_function :island_params_free, [:pointer], :void
    attach_evoasm_function :island_params_init, [:pointer], :void
    attach_evoasm_function :island_params_set_emigr_rate, [:pointer, :double], :void
    attach_evoasm_function :island_params_get_emigr_rate, [:pointer], :double
    attach_evoasm_function :island_params_set_emigr_freq, [:pointer, :uint32], :void
    attach_evoasm_function :island_params_get_emigr_freq, [:pointer], :uint32


    attach_evoasm_function :island_model_params_alloc, [], :pointer
    attach_evoasm_function :island_model_params_free, [:pointer], :void
    attach_evoasm_function :island_model_params_init, [:pointer], :void

    attach_evoasm_function :island_params_get_max_loss, [:pointer], :loss
    attach_evoasm_function :island_params_set_max_loss, [:pointer, :loss], :void

    attach_evoasm_function :deme_params_get_n_params, [:pointer], :uint8
    attach_evoasm_function :deme_params_set_size, [:pointer, :uint32], :void
    attach_evoasm_function :deme_params_set_mut_rate, [:pointer, :double], :void
    attach_evoasm_function :deme_params_set_n_params, [:pointer, :uint8], :void
    attach_evoasm_function :deme_params_set_domain, [:pointer, :uint8, :pointer], :bool
    attach_evoasm_function :deme_params_get_domain, [:pointer, :uint8], :pointer

    attach_evoasm_function :deme_seed, [:pointer], :void
    attach_evoasm_function :deme_eval, [:pointer, :loss, :pointer, :pointer], :bool
    attach_evoasm_function :deme_next_gen, [:pointer], :bool
    attach_evoasm_function :deme_get_loss, [:pointer, :pointer, :bool], :loss

    attach_evoasm_function :program_deme_alloc, [], :pointer
    attach_evoasm_function :program_deme_free, [:pointer], :void
    attach_evoasm_function :program_deme_init, [:pointer, :arch_id, :pointer], :bool
    attach_evoasm_function :program_deme_get_program, [:pointer, :pointer, :pointer], :bool

    attach_evoasm_function :program_deme_params_alloc, [], :pointer
    attach_evoasm_function :program_deme_params_free, [:pointer], :void
    attach_evoasm_function :program_deme_params_init, [:pointer], :void
    attach_evoasm_function :program_deme_params_get_min_kernel_count, [:pointer], :kernel_count
    attach_evoasm_function :program_deme_params_get_max_kernel_count, [:pointer], :kernel_count
    attach_evoasm_function :program_deme_params_get_min_kernel_size, [:pointer], :kernel_size
    attach_evoasm_function :program_deme_params_get_max_kernel_size, [:pointer], :kernel_size
    attach_evoasm_function :program_deme_params_get_recur_limit, [:pointer], :uint32
    attach_evoasm_function :program_deme_params_get_program_input, [:pointer], :pointer
    attach_evoasm_function :program_deme_params_get_program_output, [:pointer], :pointer
    attach_evoasm_function :program_deme_params_get_n_insts, [:pointer], :uint16
    attach_evoasm_function :program_deme_params_get_inst, [:pointer, :uint], :inst_id
    attach_evoasm_function :program_deme_params_set_min_kernel_count, [:pointer, :kernel_count], :void
    attach_evoasm_function :program_deme_params_set_max_kernel_count, [:pointer, :kernel_count], :void
    attach_evoasm_function :program_deme_params_set_min_kernel_size, [:pointer, :kernel_size], :void
    attach_evoasm_function :program_deme_params_set_max_kernel_size, [:pointer, :kernel_size], :void
    attach_evoasm_function :program_deme_params_set_recur_limit, [:pointer, :uint32], :void
    attach_evoasm_function :program_deme_params_set_n_insts, [:pointer, :uint16], :void
    attach_evoasm_function :program_deme_params_set_program_input, [:pointer, :pointer], :void
    attach_evoasm_function :program_deme_params_set_program_output, [:pointer, :pointer], :void
    attach_evoasm_function :program_deme_params_set_inst, [:pointer, :uint, :inst_id], :void

    attach_evoasm_function :deme_params_set_param, [:pointer, :uint, :param_id], :void
    attach_evoasm_function :deme_params_get_param, [:pointer, :uint], :param_id
    attach_evoasm_function :deme_params_get_seed, [:pointer, :uint], :uint64
    attach_evoasm_function :deme_params_set_seed, [:pointer, :uint, :uint64], :void
    attach_evoasm_function :deme_params_valid, [:pointer], :bool

    attach_evoasm_function :prng_init, [:pointer, :pointer], :void
    attach_evoasm_function :prng_alloc, [], :pointer
    attach_evoasm_function :prng_free, [:pointer], :void
    attach_evoasm_function :prng_rand64, [:pointer], :uint64
    attach_evoasm_function :prng_rand32, [:pointer], :uint32
    attach_evoasm_function :prng_rand16, [:pointer], :uint16
    attach_evoasm_function :prng_rand8, [:pointer], :uint8
    attach_evoasm_function :prng_rand_between, [:pointer, :int64, :int64], :int64

    attach_evoasm_function :program_io_alloc, [:uint16], :pointer
    attach_evoasm_function :program_io_init, [:pointer, :uint16, :varargs], :bool

    attach_evoasm_function :enum_domain_get_len, [:pointer], :uint
    attach_evoasm_function :enum_domain_get_val, [:pointer, :uint], :int64
    attach_evoasm_function :domain_alloc, [], :pointer
    attach_evoasm_function :domain_free, [:pointer], :void
    attach_evoasm_function :domain_init, [:pointer, :domain_type, :varargs], :bool
    attach_evoasm_function :domain_get_bounds, [:pointer, :pointer, :pointer], :void
    attach_evoasm_function :domain_get_type, [:pointer], :domain_type

    attach_evoasm_function :error_get_type, [:pointer], :error_type
    attach_evoasm_function :error_get_code, [:pointer], :error_code
    attach_evoasm_function :error_get_line, [:pointer], :uint32
    attach_evoasm_function :error_get_msg, [:pointer], :string
    attach_evoasm_function :error_get_filename, [:pointer], :string
  end
end


