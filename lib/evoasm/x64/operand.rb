module Evoasm
  module X64
    class Operand < FFI::Pointer
      attr_reader :instruction

      def initialize(ptr, instruction)
        super(ptr)
        @instruction = instruction
      end

      def parameter
        @instruction.parameters[Libevoasm.x64_operand_get_param_idx self]
      end

      def read?
        Libevoasm.x64_operand_is_read self
      end

      def written?
        Libevoasm.x64_operand_is_written self
      end

      def mnemonic?
        Libevoasm.x64_operand_is_mnem self
      end

      def implicit?
        Libevoasm.x64_operand_is_implicit self
      end

      def type
        Libevoasm.x64_operand_get_type self
      end

      def register
        if type == :rm || type == :reg
          reg_id = Libevoasm.x64_operand_get_reg_id self
          reg_id == :none ? nil : reg_id
        else
          nil
        end
      end

      INVALID_IMMEDIATE = -1

      def immediate
        if type == :imm
          imm = Libevoasm.x64_operand_get_imm self
          imm == INVALID_IMMEDIATE ? nil : imm
        else
          nil
        end
      end

      def register_type
        reg_type = Libevoasm.x64_operand_get_reg_type self
        reg_type == :none ? nil : reg_type
      end

      def size
        convert_size Libevoasm.x64_operand_get_size(self)
      end

      def explicit?
        !implicit?
      end

      def register_size
        if type == :rm || type == :reg
          convert_size Libevoasm.x64_operand_get_reg_size(self)
        else
          nil
        end
      end

      def index_register_size
        if type == :vsib
          convert_size Libevoasm.x64_operand_get_index_reg_size(self)
        else
          nil
        end
      end

      def memory_size
        if type == :rm || type == :mem || type == :vsib
          convert_size Libevoasm.x64_operand_get_mem_size(self)
        else
          nil
        end
      end

      private

      def convert_size(size)
        case size
        when :'1' then
          1
        when :'8' then
          8
        when :'16' then
          16
        when :'32' then
          32
        when :'64' then
          64
        when :'128' then
          128
        when :'256' then
          256
        when :'512' then
          512
        else
          nil
        end
      end
    end
  end
end