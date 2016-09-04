module Evoasm
  module X64
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

      def mnemonic?
        Libevoasm.x64_operand_mnem self
      end

      def implicit?
        Libevoasm.x64_operand_implicit self
      end

      def type
        Libevoasm.x64_operand_type self
      end

      def register
        if type == :rm || type == :reg
          reg_id = Libevoasm.x64_operand_reg_id self
          reg_id == :n_regs ? nil : reg_id
        else
          nil
        end
      end

      INVALID_IMMEDIATE = -1

      def immediate
        if type == :imm
          imm = Libevoasm.x64_operand_imm self
          imm == INVALID_IMMEDIATE ? nil : imm
        else
          nil
        end
      end

      def register_type
        reg_type = Libevoasm.x64_operand_reg_type self
        reg_type == :n_reg_types ? nil : reg_type
      end

      def size
        convert_size Libevoasm.x64_operand_size(self)
      end

      def explicit?
        !implicit?
      end

      def memory_size
        if type == :rm || type == :mem
          convert_size Libevoasm.x64_operand_mem_size(self)
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