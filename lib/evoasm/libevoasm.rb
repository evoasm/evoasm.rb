require 'evoasm/ffi_ext'

module Evoasm
  # @!visibility private
  module Libevoasm
    extend FFI::Library

    require 'evoasm/libevoasm/x64_enums'
    require 'evoasm/libevoasm/enums'

    GEM_LIBEVOASM_FILENAME = File.join(Evoasm.ext_dir, 'evoasm_ext', FFI.map_library_name('evoasm'))
    DEV_LIBEVOASM_FILENAME = File.join(Evoasm.root_dir, '..', 'libevoasm', 'cmake-build-debug', FFI.map_library_name('evoasm'))

    lib_filename =
      if !ARGV.include?('--use-gem-libevoasm') && File.exist?(DEV_LIBEVOASM_FILENAME)
        DEV_LIBEVOASM_FILENAME
      else
        GEM_LIBEVOASM_FILENAME
      end

    ffi_lib lib_filename

    enum :kernel_io_val_type, %i(
      u8x1
      i8x1
      u8x2
      i8x2
      u8x4
      i8x4
      u8x8
      i8x8
      i8x16
      u8x16
      i8x32
      u8x32
      u16x1
      i16x1
      u16x2
      i16x2
      u16x4
      i16x4
      u16x8
      i16x8
      u16x16
      i16x16
      u32x1
      i32x1
      u32x2
      i32x2
      u32x4
      i32x4
      u32x8
      i32x8
      i64x1
      u64x1
      i64x2
      u64x2
      i64x4
      u64x4
      f32x1
      f32x2
      f32x4
      f32x8
      f64x1
      f64x2
      f64x4
    )

    typedef :uint16, :inst_id
    typedef :uint8, :reg_id
    typedef :uint8, :param_id
    typedef :float, :loss

    enum :domain_type, [
      :enum,
      :range,
    ]

    enum :range_domain_type, [
      :int8,
      :int16,
      :int32,
      :int64,
      :custom
    ]

    enum :arch_id, [
      :x64
    ]

    enum :error_type, [
      :buf,
      :alloc,
      :arch,
      :kernel,
      :pop_params,
      :pop
    ]

    enum :error_code, [
      :missing_parameter,
      :not_encodable
    ]

    enum :x64_insts_flags, [
      :include_useless, 1 << 0,
      :only_basic, 1 << 1
    ]

    enum :buf_type, [
      :mmap,
      :malloc,
      :none
    ]

    enum :log_level, [
      :trace,
      :debug,
      :info,
      :warn,
      :error,
      :fatal,
      :none
    ]

    enum :mprot_mode, [
      :rw,
      :rx,
      :rwx
    ]

    enum :x64_abi, [
      :sysv
    ]

    enum :x64_cpu_state_flags, [
      :ip, 1 << 0,
      :sp, 1 << 1,
      :mxcsr, 1 << 2,
      :rflags, 1 << 3,
    ]

    enum :x64_operand_size, [
      :'8',
      :'16',
      :'32',
      :'64',
      :'128',
      :'256',
      :'512',
      :none
    ]

    enum :x64_operand_word, [
      :lb,
      :hb,
      :w,
      :dw,
      :lqw,
      :hqw,
      :dqw,
      :vw,
      :none,
    ]

    enum :x64_jmp_cond, [
      :ja,
      :jae,
      :jb,
      :jbe,
      :je,
      :jg,
      :jge,
      :jl,
      :jle,
      :jne,
      :jno,
      :jnp,
      :jns,
      :jo,
      :jp,
      :js,
      :none
    ]


    def self.attach_evoasm_function(name, args, returns, options = {})
      attach_function name, :"evoasm_#{name}", args, returns, options
    end

    attach_evoasm_function :init, [:int, :pointer, :pointer], :void
    attach_evoasm_function :get_last_error, [], :pointer
    attach_evoasm_function :set_log_level, [:log_level], :void

    attach_evoasm_function :get_arch_info, [:arch_id], :pointer
    attach_evoasm_function :arch_info_get_features, [:pointer], :uint64
    attach_evoasm_function :arch_info_get_n_conds, [:pointer], :size_t
    attach_evoasm_function :get_current_arch, [], :arch_id

    attach_evoasm_function :buf_ref_alloc, [], :pointer
    attach_evoasm_function :buf_ref_init, [:pointer, :pointer, :pointer], :void
    attach_evoasm_function :buf_ref_free, [:pointer], :void

    attach_evoasm_function :buf_alloc, [], :pointer
    attach_evoasm_function :buf_init, [:pointer, :buf_type, :size_t], :bool
    attach_evoasm_function :buf_free, [:pointer], :void
    attach_evoasm_function :buf_destroy, [:pointer], :void
    attach_evoasm_function :buf_exec, [:pointer], :size_t
    attach_evoasm_function :buf_safe_exec, [:pointer, :uint64, :pointer], :bool
    attach_evoasm_function :buf_log, [:pointer, :log_level], :void
    attach_evoasm_function :buf_reset, [:pointer], :void
    attach_evoasm_function :buf_protect, [:pointer, :mprot_mode], :bool
    attach_evoasm_function :buf_to_buf_ref, [:pointer, :pointer], :void
    attach_evoasm_function :buf_get_capa, [:pointer], :size_t
    attach_evoasm_function :buf_get_pos, [:pointer], :size_t
    attach_evoasm_function :buf_get_data, [:pointer], :pointer
    attach_evoasm_function :buf_get_type, [:pointer], :buf_type
    attach_evoasm_function :buf_write, [:pointer, :pointer, :size_t], :size_t

    attach_evoasm_function :x64_cpu_state_alloc, [], :pointer
    attach_evoasm_function :x64_cpu_state_init, [:pointer, :int], :void
    attach_evoasm_function :x64_cpu_state_free, [:pointer], :void
    attach_evoasm_function :x64_cpu_state_destroy, [:pointer], :void
    attach_evoasm_function :x64_cpu_state_set, [:pointer, :x64_reg_id, :pointer, :size_t], :void
    attach_evoasm_function :x64_cpu_state_get, [:pointer, :x64_reg_id, :x64_operand_word, :pointer, :size_t], :size_t
    attach_evoasm_function :x64_cpu_state_get_rflags_flag, [:pointer, :x64_rflags_flag], :bool
    attach_evoasm_function :x64_cpu_state_clone, [:pointer, :pointer], :void
    attach_evoasm_function :x64_cpu_state_xor, [:pointer, :pointer, :pointer], :void
    attach_evoasm_function :x64_cpu_state_calc_dist, [:pointer, :pointer, :metric], :double
    attach_evoasm_function :x64_cpu_state_memset, [:pointer, :int], :void
    attach_evoasm_function :x64_cpu_state_emit_load, [:pointer, :pointer], :bool
    attach_evoasm_function :x64_cpu_state_emit_store, [:pointer, :pointer], :bool
    attach_evoasm_function :x64_cpu_state_rand, [:pointer, :pointer], :void

    attach_evoasm_function :x64_params_init, [:pointer], :void
    attach_evoasm_function :x64_params_alloc, [], :pointer
    attach_evoasm_function :x64_params_free, [:pointer], :void
    attach_evoasm_function :x64_params_set, [:pointer, :x64_param_id, :int64], :void
    attach_evoasm_function :x64_params_get, [:pointer, :x64_param_id], :int64
    attach_evoasm_function :x64_param_get_type, [:x64_param_id], :x64_param_type
    attach_evoasm_function :x64_params_rand, [:pointer, :pointer, :pointer], :bool
    attach_evoasm_function :x64_params_rand2, [:pointer, :pointer, :pointer, :pointer], :bool

    attach_evoasm_function :x64_basic_params_init, [:pointer], :void
    attach_evoasm_function :x64_basic_params_alloc, [], :pointer
    attach_evoasm_function :x64_basic_params_free, [:pointer], :void
    attach_evoasm_function :x64_basic_params_set, [:pointer, :x64_basic_param_id, :int64], :void
    attach_evoasm_function :x64_basic_params_get, [:pointer, :x64_basic_param_id], :int64
    attach_evoasm_function :x64_basic_param_get_type, [:x64_basic_param_id], :x64_param_type

    attach_evoasm_function :param_get_id, [:pointer], :int
    attach_evoasm_function :param_get_domain, [:pointer], :pointer

    attach_evoasm_function :x64_init, [], :bool
    attach_evoasm_function :x64_get_insts, [:uint64, :uint64, :uint64, :uint64, :pointer], :size_t
    attach_evoasm_function :x64_get_inst, [:x64_inst_id], :pointer

    attach_evoasm_function :x64_enc, [:x64_inst_id, :pointer, :pointer], :bool
    attach_evoasm_function :x64_enc_basic, [:x64_inst_id, :pointer, :pointer], :bool

    attach_evoasm_function :x64_emit_func_prolog, [:x64_abi, :pointer], :bool
    attach_evoasm_function :x64_emit_func_epilog, [:x64_abi, :pointer], :bool

    attach_evoasm_function :x64_inst_get_param, [:pointer, :size_t], :pointer
    attach_evoasm_function :x64_inst_get_n_params, [:pointer], :size_t
    attach_evoasm_function :x64_inst_get_operand, [:pointer, :size_t], :pointer
    attach_evoasm_function :x64_inst_get_n_operands, [:pointer], :size_t
    attach_evoasm_function :x64_inst_get_mnem, [:pointer], :string
    attach_evoasm_function :x64_inst_enc, [:pointer, :pointer, :pointer], :bool
    attach_evoasm_function :x64_inst_enc_basic, [:pointer, :pointer, :pointer], :bool
    attach_evoasm_function :x64_inst_is_basic, [:pointer], :bool

    attach_evoasm_function :x64_operand_get_param_idx, [:pointer], :size_t
    attach_evoasm_function :x64_operand_is_read, [:pointer], :bool
    attach_evoasm_function :x64_operand_is_written, [:pointer], :bool
    attach_evoasm_function :x64_operand_is_maybe_written, [:pointer], :bool
    attach_evoasm_function :x64_operand_is_implicit, [:pointer], :bool
    attach_evoasm_function :x64_operand_is_mnem, [:pointer], :bool
    attach_evoasm_function :x64_operand_get_type, [:pointer], :x64_operand_type
    attach_evoasm_function :x64_operand_get_word, [:pointer, :pointer, :pointer], :x64_operand_word
    attach_evoasm_function :x64_operand_get_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_reg_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_index_reg_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_mem_size, [:pointer], :x64_operand_size
    attach_evoasm_function :x64_operand_get_reg_type, [:pointer], :x64_reg_type
    attach_evoasm_function :x64_operand_get_reg_id, [:pointer], :x64_reg_id
    attach_evoasm_function :x64_operand_get_imm, [:pointer], :int8

    attach_evoasm_function :kernel_destroy, [:pointer], :bool
    attach_evoasm_function :kernel_alloc, [], :pointer
    attach_evoasm_function :kernel_free, [:pointer], :void
    attach_evoasm_function :kernel_run, [:pointer, :pointer, :pointer], :bool

    attach_evoasm_function :kernel_get_size, [:pointer], :size_t
    attach_evoasm_function :kernel_get_code, [:pointer, :bool, :pointer], :size_t

    attach_evoasm_function :kernel_get_input_type, [:pointer, :size_t], :kernel_io_val_type
    attach_evoasm_function :kernel_get_output_type, [:pointer, :size_t], :kernel_io_val_type
    attach_evoasm_function :kernel_get_input_arity, [:pointer], :size_t
    attach_evoasm_function :kernel_get_output_arity, [:pointer], :size_t

    attach_evoasm_function :kernel_elim_introns, [:pointer, :pointer], :bool
    attach_evoasm_function :kernel_is_input_reg, [:pointer, :size_t, :uint8], :bool
    attach_evoasm_function :kernel_is_output_reg, [:pointer, :size_t, :uint8], :bool
    attach_evoasm_function :kernel_get_output_reg, [:pointer, :size_t], :reg_id
    attach_evoasm_function :kernel_get_arity, [:pointer], :size_t

    attach_evoasm_function :kernel_io_alloc, [], :pointer
    attach_evoasm_function :kernel_io_free, [:pointer], :void
    attach_evoasm_function :kernel_io_init, [:pointer, :size_t, :size_t, :pointer], :bool
    attach_evoasm_function :kernel_io_get_arity, [:pointer], :size_t
    attach_evoasm_function :kernel_io_get_n_vals, [:pointer], :size_t
    attach_evoasm_function :kernel_io_get_n_tuples, [:pointer], :size_t
    attach_evoasm_function :kernel_io_get_type, [:pointer, :size_t], :kernel_io_val_type
    attach_evoasm_function :kernel_io_get_val, [:pointer, :size_t, :size_t], :pointer
    attach_evoasm_function :kernel_io_destroy, [:pointer], :void
    attach_evoasm_function :kernel_io_val_type_get_len, [:kernel_io_val_type], :size_t
    attach_evoasm_function :kernel_io_val_type_get_elem_type, [:kernel_io_val_type], :kernel_io_val_type
    attach_evoasm_function :kernel_io_val_type_make, [:kernel_io_val_type, :size_t], :kernel_io_val_type

    attach_evoasm_function :pop_seed, [:pointer, :pointer], :bool
    attach_evoasm_function :pop_eval, [:pointer, :size_t], :bool
    attach_evoasm_function :pop_next_gen, [:pointer], :bool

    attach_evoasm_function :pop_alloc, [], :pointer
    attach_evoasm_function :pop_destroy, [:pointer], :void
    attach_evoasm_function :pop_free, [:pointer], :void
    attach_evoasm_function :pop_init, [:pointer, :arch_id, :pointer], :bool
    attach_evoasm_function :pop_calc_summary, [:pointer, :pointer], :bool
    attach_evoasm_function :pop_get_best_loss, [:pointer], :loss
    attach_evoasm_function :pop_get_gen_counter, [:pointer], :size_t
    attach_evoasm_function :pop_summary_len, [:pointer], :size_t
    attach_evoasm_function :pop_load_best_kernel, [:pointer, :pointer], :bool

    attach_evoasm_function :deme_kernels_alloc, [], :pointer
    attach_evoasm_function :deme_kernels_free, [:pointer], :void
    attach_evoasm_function :deme_kernels_init, [:pointer, :pointer, :arch_id, :size_t], :bool
    attach_evoasm_function :deme_kernels_destroy, [:pointer], :void

    attach_evoasm_function :deme_kernels_set_inst, [:pointer, :size_t, :size_t, :inst_id, :pointer], :void
    attach_evoasm_function :deme_kernels_set_size, [:pointer, :size_t, :size_t], :void

    # attach_evoasm_function :pop_params_get_mut_rate, [:pointer], :float
    attach_evoasm_function :pop_params_get_n_params, [:pointer], :uint8
    # attach_evoasm_function :pop_params_set_mut_rate, [:pointer, :float], :void
    attach_evoasm_function :pop_params_set_n_params, [:pointer, :uint8], :void
    attach_evoasm_function :pop_params_set_domain, [:pointer, :uint8, :pointer], :bool
    attach_evoasm_function :pop_params_get_domain, [:pointer, :uint8], :pointer
    attach_evoasm_function :pop_params_alloc, [], :pointer
    attach_evoasm_function :pop_params_free, [:pointer], :void
    attach_evoasm_function :pop_params_init, [:pointer], :void
    attach_evoasm_function :pop_params_get_kernel_input, [:pointer], :pointer
    attach_evoasm_function :pop_params_get_kernel_output, [:pointer], :pointer
    attach_evoasm_function :pop_params_get_n_insts, [:pointer], :uint16
    attach_evoasm_function :pop_params_get_inst, [:pointer, :size_t], :inst_id
    attach_evoasm_function :pop_params_get_deme_size, [:pointer], :uint16
    attach_evoasm_function :pop_params_set_deme_size, [:pointer, :uint16], :void
    attach_evoasm_function :pop_params_get_n_demes, [:pointer], :uint16
    attach_evoasm_function :pop_params_set_n_demes, [:pointer, :uint16], :void
    attach_evoasm_function :pop_params_get_tourn_size, [:pointer], :uint8
    attach_evoasm_function :pop_params_set_tourn_size, [:pointer, :uint8], :void
    attach_evoasm_function :pop_params_get_example_win_size, [:pointer], :uint16
    attach_evoasm_function :pop_params_set_example_win_size, [:pointer, :uint16], :void
    attach_evoasm_function :pop_params_set_min_kernel_size, [:pointer, :uint16], :void
    attach_evoasm_function :pop_params_set_max_kernel_size, [:pointer, :uint16], :void
    attach_evoasm_function :pop_params_get_min_kernel_size, [:pointer], :uint16
    attach_evoasm_function :pop_params_get_max_kernel_size, [:pointer], :uint16
    attach_evoasm_function :pop_params_set_n_insts, [:pointer, :uint16], :void
    attach_evoasm_function :pop_params_set_kernel_input, [:pointer, :pointer], :void
    attach_evoasm_function :pop_params_set_kernel_output, [:pointer, :pointer], :void
    attach_evoasm_function :pop_params_set_inst, [:pointer, :size_t, :inst_id], :void
    attach_evoasm_function :pop_params_set_param, [:pointer, :size_t, :param_id], :void
    attach_evoasm_function :pop_params_get_param, [:pointer, :size_t], :param_id
    attach_evoasm_function :pop_params_get_seed, [:pointer, :size_t], :uint64
    attach_evoasm_function :pop_params_set_seed, [:pointer, :size_t, :uint64], :void
    attach_evoasm_function :pop_params_get_dist_metric, [:pointer], :metric
    attach_evoasm_function :pop_params_set_dist_metric, [:pointer, :metric], :void
    attach_evoasm_function :pop_params_validate, [:pointer], :bool
    attach_evoasm_function :pop_params_get_n_local_search_iters, [:pointer], :size_t
    attach_evoasm_function :pop_params_set_n_local_search_iters, [:pointer, :size_t], :void

    attach_evoasm_function :prng_init, [:pointer, :pointer], :void
    attach_evoasm_function :prng_alloc, [], :pointer
    attach_evoasm_function :prng_free, [:pointer], :void
    attach_evoasm_function :prng_rand64, [:pointer], :uint64
    attach_evoasm_function :prng_rand32, [:pointer], :uint32
    attach_evoasm_function :prng_rand16, [:pointer], :uint16
    attach_evoasm_function :prng_rand8, [:pointer], :uint8
    attach_evoasm_function :prng_randf, [:pointer], :float
    attach_evoasm_function :prng_rand_between, [:pointer, :int64, :int64], :int64

    attach_evoasm_function :enum_domain_get_len, [:pointer], :size_t
    attach_evoasm_function :enum_domain_get_val, [:pointer, :size_t], :int64
    attach_evoasm_function :range_domain_get_type, [:pointer], :range_domain_type
    attach_evoasm_function :domain_alloc, [], :pointer
    attach_evoasm_function :domain_free, [:pointer], :void
    attach_evoasm_function :domain_rand, [:pointer, :pointer], :int64
    attach_evoasm_function :domain_init, [:pointer, :domain_type, :varargs], :bool
    attach_evoasm_function :domain_get_bounds, [:pointer, :pointer, :pointer], :void
    attach_evoasm_function :domain_get_type, [:pointer], :domain_type

    attach_evoasm_function :error_get_type, [:pointer], :error_type
    attach_evoasm_function :error_get_code, [:pointer], :error_code
    attach_evoasm_function :error_get_line, [:pointer], :uint
    attach_evoasm_function :error_get_msg, [:pointer], :string
    attach_evoasm_function :error_get_filename, [:pointer], :string
  end

end


