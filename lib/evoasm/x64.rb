require 'evoasm/libevoasm'
require 'evoasm/capstone'

module Evoasm
  class X64 < FFI::AutoPointer
    class Error < StandardError
      attr_reader :type, :line, :filename

      def self.last
        self.new(Libevoasm.last_error)
      end

      def initialize(error)
        super(error.msg)
        @line = error.line
        @type = error.type
        @filename = error.filename
      end

      def to_s
        "#{@filename}:#{@line}: #{message}"
      end
    end


    def self.disassemble(asm)
      Evoasm::Capstone.disassemble_x64 asm
    end

    def encode(inst_id, params)
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

      params_ary.write_array_of_int64 param_vals
      bitmap_ptr.write_uint64 bitmap

      success = Libevoasm.arch_enc self, inst_id, params_ary, bitmap_ptr
      if success
        buf = FFI::MemoryPointer.new :uint8, 255
        len = Libevoasm.arch_save2 self, buf
        buf.read_string len
      else
        raise Error.last
      end
    end

    def initialize
      ptr = Libevoasm.x64_alloc
      Libevoasm.x64_init ptr
      super(ptr)
    end

    def instructions(*flags)
      insts_enum = Libevoasm.enum_type(:x64_inst_id)
      insts_flags_enum = Libevoasm.enum_type(:x64_insts_flags)

      n_insts = insts_enum[:n_insts]
      array = FFI::MemoryPointer.new :int, n_insts
      len = Libevoasm.arch_insts(self, array, insts_flags_enum.flags(flags))
      insts = array.read_array_of_type(:int, :read_int, len)

      insts.map { |e| insts_enum[e] }
    end

    def self.release(ptr)
      Libevoasm.x64_destroy(ptr)
      Libevoasm.x64_free(ptr)
    end
  end
end