module Evoasm
  module Libevoasm
    attach_evoasm_function :init, [:int, :pointer, :pointer], :void
    attach_evoasm_function :last_error, [], Error.by_ref
    attach_evoasm_function :set_min_log_level, [:log_level], :void


    attach_evoasm_function :search_alloc, [], :pointer
    attach_evoasm_function :search_free, [:pointer], :void
    attach_evoasm_function :search_init, [:pointer, :pointer, SearchParams.by_ref], :bool
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
    attach_evoasm_function :param_domain, [:pointer], Domain.by_ref

    attach_evoasm_function :x64_init, [], :void
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
    attach_evoasm_function :adf_run, [:pointer, ADFInput.by_ref, ADFOutput.by_ref], :bool

    attach_evoasm_function :adf_size, [:pointer], :adf_size
    attach_evoasm_function :adf_kernel_code, [:pointer, :uint, :pointer], :size_t
    attach_evoasm_function :adf_code, [:pointer, :bool, :pointer], :size_t
    attach_evoasm_function :adf_kernel_alt_succ, [:pointer, :uint], :uint
    attach_evoasm_function :adf_eliminate_introns, [:pointer], :bool
    attach_evoasm_function :adf_is_input_reg, [:pointer, :uint, :uint8], :bool
    attach_evoasm_function :adf_is_output_reg, [:pointer, :uint, :uint8], :bool

  end
end