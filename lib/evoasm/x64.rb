require 'evoasm/libevoasm'
require 'evoasm/capstone'

module Evoasm
  class X64 < FFI::AutoPointer

    class Instruction < FFI::Pointer

      class Parameter < FFI::Pointer
        def name
          Libevoasm.enum_type(:x64_inst_param_id).find Libevoasm.inst_param_id(self)
        end

        def domain
          Libevoasm.inst_param_domain(self).to_ruby
        end
      end

      attr_reader :name

      def initialize(ptr, name, x64)
        super(ptr)
        @name = name
        @x64 = x64
      end

      def operands
        n_operands = Libevoasm.x64_inst_n_operands self
        Array.new(n_operands) do |operand_index|
          Operand.new Libevoasm.x64_inst_operand(self, operand_index), self
        end
      end

      def parameters
        n_params = Libevoasm.x64_inst_n_params self
        Array.new(n_params) do |param_index|
          Parameter.new Libevoasm.x64_inst_param(self, param_index)
        end
      end

      def encode(params)
        @x64.encode name, params
      end
    end

    class Operand < FFI::Pointer
      def initialize(ptr, instruction)
        super(ptr)
        @instruction = instruction
      end

      def parameter
        @instruction.parameters[Libevoasm.x64_operand_param_idx self]
      end

      def read?
        Libevoasm.x64_operand_read self
      end

      def written?
        Libevoasm.x64_operand_written self
      end

      def implicit?
        Libevoasm.x64_operand_implicit self
      end

      def type
        Libevoasm.x64_operand_type self
      end

      def register
        reg_id = Libevoasm.x64_operand_reg_id self
        reg_id == :n_regs ? nil : reg_id
      end

      def register_type
        reg_type = Libevoasm.x64_operand_reg_type self
        reg_type == :n_reg_types ? nil : reg_type
      end

      def size
        size = Libevoasm.x64_operand_size self

        case size
        when :'8' then 8
        when :'16' then 16
        when :'32' then 32
        when :'64' then 64
        when :'128' then 128
        when :'256' then 256
        when :'512' then 512
        else
          nil
        end
      end

      def explicit?
        !implicit?
      end
    end

    def self.disassemble(asm, addr = nil)
      Evoasm::Capstone.disassemble_x64 asm, addr
    end

    def initialize
      ptr = Libevoasm.x64_alloc
      Libevoasm.x64_init ptr
      super(ptr)
    end

    private def convert_encode_params(params)
      Libevoasm.enum_hash_to_mem_ptr(params, :int64, :x64_inst_param_id, :n_inst_params, bitmap: true) do |ptr, value|
        ptr.put_int64 0, Libevoasm::ParamVal.for(value)
      end
    end

    def encode(inst, params)
      params_ptr, bitmap_ptr = convert_encode_params(params)

      success = Libevoasm.x64_enc self, inst, params_ptr, bitmap_ptr
      if success
        buf = FFI::MemoryPointer.new :uint8, 255
        len = Libevoasm.arch_save2 self, buf
        buf.read_string len
      else
        raise Error.last
      end
    end

    def features
      feature_enum_type = Libevoasm.enum_type(:x64_feature)
      features_as_flags = Libevoasm.x64_features self
      feature_enum_type.symbol_map.each_with_object([]) do |(k, v), acc|
        acc << k if features_as_flags & (1 << v)
      end
    end

    def instruction(inst_name)
      Instruction.new Libevoasm.x64_inst(self, inst_name), inst_name, self
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