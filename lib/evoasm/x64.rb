require 'evoasm/libevoasm'
require 'evoasm/capstone'

module Evoasm
  class X64 < FFI::AutoPointer
    def self.disassemble(asm)
      Evoasm::Capstone.disassemble_x64 asm
    end

    def encode(inst_id, params)
      return
      params_enum = Libevoasm.enum_type(:x64_param_id)

      n_params = params_enum[:n_params]
      bitmap_ptr = FFI::MemoryPointer.new :uint64
      params_ary = FFI::MemoryPointer.new :int64, n_params

      params = params.map do |param, value|
        enum_val = params_enum[param]
        raise ArgumentError, "invalid param '#{param}'" if enum_val.nil?
        [enum_val, value]
      end.to_h

      bitmap = params.inject(0) do |acc, (param_id, value)|
        acc | (1 << param_id)
      end

      p params
      param_vals = Array.new(n_params) do |index|
        value = params[index]
        case value
        when Symbol
          int_value = Libevoasm.enum_value value
          if int_value.nil?
            raise ArgumentError, "unknown value '#{value}'"
          end
          int_value
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

      p param_vals

      params_ary.write_array_of_int64 param_vals
      bitmap_ptr.write_uint64 bitmap

      p bitmap


      Libevoasm.arch_enc @ptr, inst_id, params_ary, bitmap_ptr
    end

    def initialize
      @ptr = FFI::MemoryPointer.new :uchar, Libevoasm.sizeof_x64
      Libevoasm.x64_init @ptr
      super(@ptr)
    end

    def instructions
      n_insts = Libevoasm.enum_value :n_insts
      array = FFI::MemoryPointer.new :uint16, n_insts
      len = Libevoasm.arch_insts(@ptr, array)
      p len
      insts = array.read_array_of_type(:int, :get_int, len)

      raise insts.inspect
    end

    def self.release(ptr)
      Libevoasm.x64_destroy(ptr)
    end
  end
end