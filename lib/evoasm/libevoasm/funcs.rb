module Evoasm
  module Libevoasm
    attach_evoasm_function :init, [:int, :pointer, :pointer], :void
    attach_evoasm_function :last_error, [], Error.by_ref
    attach_evoasm_function :set_min_log_level, [:log_level], :void


    attach_evoasm_function :search_alloc, [], :pointer
    attach_evoasm_function :search_free, [:pointer], :void
    attach_evoasm_function :search_init, [:pointer, :pointer, SearchParams.by_ref], :bool
    attach_evoasm_function :search_destroy, [:pointer], :void
    callback :result_func, [:pointer, :loss, :pointer], :bool
    attach_evoasm_function :search_start, [:pointer, :result_func, :pointer], :void

    attach_evoasm_function :arch_save2, [:pointer, :pointer], :size_t

    attach_evoasm_function :x64_alloc, [], :pointer
    attach_evoasm_function :x64_free, [:pointer], :void
    attach_evoasm_function :x64_init, [:pointer], :bool
    attach_evoasm_function :x64_destroy, [:pointer], :void
    attach_evoasm_function :x64_insts, [:pointer, :uint64, :uint64, :uint64, :uint64, :pointer], :uint16
    attach_evoasm_function :x64_enc, [:pointer, :x64_inst_id, :pointer, :pointer], :bool
    attach_evoasm_function :x64_features, [:pointer], :uint64

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
    attach_evoasm_function :adf_kernel_is_input_reg, [:pointer, :uint, :uint8], :bool
  end
end