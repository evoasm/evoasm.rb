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


    def self.disassemble(asm, addr = nil)
      Evoasm::Capstone.disassemble_x64 asm, addr
    end

    private def convert_encode_params(params)
      Libevoasm.enum_hash_to_array(params, :x64_param_id, :n_params) do |value|
        Libevoasm::ParamVal.for value
      end
    end

    def encode(inst_id, params)
      params_values, params_bitmap, n_params = convert_encode_params params

      bitmap_ptr = FFI::MemoryPointer.new :uint64
      params_ary = FFI::MemoryPointer.new :int64, n_params

      params_ary.write_array_of_int64 params_values
      bitmap_ptr.write_uint64 params_bitmap

      success = Libevoasm.x64_enc self, inst_id, params_ary, bitmap_ptr
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

    def features
      feature_enum_type = Libevoasm.enum_type(:x64_feature)
      features_as_flags = Libevoasm.x64_features self
      feature_enum_type.symbol_map.each_with_object([]) do |(k, v), acc|
        acc << k if features_as_flags & (1 << v)
      end
    end

    def instructions(*reg_types, operand_types: [:reg, :rm, :imm], search: true, features: nil)
      inst_id_enum_type = Libevoasm.enum_type(:x64_inst_id)
      feature_enum_type = Libevoasm.enum_type(:x64_feature)
      insts_flags_enum_type = Libevoasm.enum_type(:x64_insts_flags)
      op_type_enum_type = Libevoasm.enum_type(:x64_operand_type)
      reg_type_enum_type = Libevoasm.enum_type(:x64_reg_type)

      flags = []

      flags << :search if search
      flags_as_flags = insts_flags_enum_type.flags flags, shift: false

      features_as_flags =
        if features.nil?
          Libevoasm.x64_features self
        else
          feature_enum_type.flags features, shift: true
        end
      op_types_as_flags = op_type_enum_type.flags operand_types, shift: true
      reg_types_as_flags = reg_type_enum_type.flags reg_types, shift: true

      n_insts = inst_id_enum_type[:n_insts]
      array = FFI::MemoryPointer.new :int, n_insts
      len = Libevoasm.x64_insts(self, flags_as_flags, features_as_flags,
                                 op_types_as_flags, reg_types_as_flags, array)
      insts = array.read_array_of_type(:int, :read_int, len)

      insts.map { |e| inst_id_enum_type[e] }
    end

    def self.release(ptr)
      Libevoasm.x64_destroy(ptr)
      Libevoasm.x64_free(ptr)
    end
  end
end