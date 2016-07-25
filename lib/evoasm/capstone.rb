require 'ffi'

module Evoasm
  module Capstone
    class Error < StandardError; end

    module LibCapstone
      extend FFI::Library

      ffi_lib ['capstone', 'libcapstone.so.3']

      class Insn < FFI::Struct
        layout :id, :uint,
               :address, :uint64,
               :size, :uint16,
               :bytes, [:uchar, 16],
               :mnemonic, [:char, 32],
               :op_str, [:char, 160],
               :detail, :pointer
      end

      enum :cs_mode, [
        :mode_64, 1 << 3
      ]

      enum :cs_arch, [
        :arch_x86, 3
      ]

      enum :cs_err, [
        	:err_ok, 0,
	        :err_mem,
          :err_arch,
	        :err_handle,
        	:err_csh,
        	:err_mode,
        	:err_option,
        	:err_detail,
        	:err_memsetup,
        	:err_version,
        	:err_diet,
        	:err_skipdata,
        	:err_x86_att,
        	:err_x86_intel,
      ]

      typedef :pointer, :cs_insn
      typedef :size_t, :csh
      typedef :pointer, :csh_ptr

      attach_function :cs_close, [:csh_ptr], :cs_err
      attach_function :cs_open, [:cs_arch, :cs_mode, :csh_ptr], :cs_err
      attach_function :cs_strerror, [:cs_err], :string
      attach_function :cs_free, [:pointer, :size_t], :void
      attach_function :cs_disasm, [:csh, :pointer, :size_t, :uint64, :size_t, :pointer], :size_t
      attach_function :cs_errno, [:csh], :cs_err
    end

    def self.disassemble_x64(asm, addr = nil)
      result = []
      handle_ptr = FFI::MemoryPointer.new(:size_t, 1)

      err = LibCapstone.cs_open :arch_x86, :mode_64, handle_ptr
      if err != :err_ok
        raise Error, cs_strerror(err);
      end

      handle = handle_ptr.read_size_t

      insns_ptr = FFI::MemoryPointer.new :pointer
      count = LibCapstone.cs_disasm(handle, asm, asm.bytesize, addr ? addr : 0, 0, insns_ptr)
      insns = insns_ptr.read_pointer
      if count > 0
        count.times do |c|
          insn_ptr = insns + c * LibCapstone::Insn.size
          insn = LibCapstone::Insn.new insn_ptr
          line = []
          line << insn[:address] if addr
          line << insn[:mnemonic].to_s << insn[:op_str].to_s
          result << line
        end
        err = nil
      else
        err = LibCapstone.cs_errno handle
      end

      LibCapstone.cs_free insns, count
      LibCapstone.cs_close handle_ptr

      if err
        raise Error, cs_strerror(err);
      end

      result
    end
  end


end