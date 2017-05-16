module Evoasm
  module X64
    # Represents a formal instruction operand
    class Operand < FFI::Pointer

      # @return [X64::Instruction] the instruction this operand belongs to
      attr_reader :instruction

      # @!visibility private
      def initialize(ptr, instruction)
        super(ptr)
        @instruction = instruction
      end

      # Gives the parameter affecting this operand
      # @return [X64::Parameter] the parameter
      def parameter
        @instruction.parameters[Libevoasm.x64_operand_get_param_idx self]
      end

      # Returns whether this operand is read
      def read?
        Libevoasm.x64_operand_is_read self
      end

      # Returns whether this operand is written
      def written?
        Libevoasm.x64_operand_is_written self
      end

      # Returns whether this operand is possibliy written (e.g. in a conditional move instruction)
      def maybe_written?
        Libevoasm.x64_operand_is_maybe_written self
      end

      # Returns whether this operand is part of the instruction mnemonic
      def mnemonic?
        Libevoasm.x64_operand_is_mnem self
      end

      # Returns whether this operand is implicit
      def implicit?
        Libevoasm.x64_operand_is_implicit self
      end

      # Returns whether this operand is explicit
      def explicit?
        !implicit?
      end

      # Returns the operand type
      # @return [:rm, :imm, :reg] the operand type
      def type
        Libevoasm.x64_operand_get_type self
      end

      # Returns the operand's register (e.g. if implicit) if available
      # @return [Symbol, nil] the operand's register or nil if there is none
      def register
        if type == :rm || type == :reg
          reg_id = Libevoasm.x64_operand_get_reg_id self
          reg_id == :none ? nil : reg_id
        else
          nil
        end
      end

      INVALID_IMMEDIATE = -1

      # Returns the operand's immediate (e.g. if implicit) if available
      # @return [Integer, nil] the operand's immediate or nil if there is none
      def immediate
        if type == :imm
          imm = Libevoasm.x64_operand_get_imm self
          imm == INVALID_IMMEDIATE ? nil : imm
        else
          nil
        end
      end

      # Returns the operand's register type (e.g. if implicit) if available
      # @return [Symbol, nil] the operand's register type or nil if there is none
      def register_type
        reg_type = Libevoasm.x64_operand_get_reg_type self
        reg_type == :none ? nil : reg_type
      end

      # Gives the operand's size
      # @return [Integer] the operand size in bits
      def size
        convert_size Libevoasm.x64_operand_get_size(self)
      end

      # Gives the operand's word
      # @param instruction [Instruction] instruction this parameter belongs to
      # @param parameters [Parameters] parameters
      # @return [Symbol] the operand word
      def word(instruction = nil, parameters = nil)
        Libevoasm.x64_operand_get_word(self, instruction, parameters)
      end

      # Returns the operand's register size
      # @return [Integer, nil] the operand's registert size or nil if this operand does not hold a register
      def register_size
        if type == :rm || type == :reg
          convert_size Libevoasm.x64_operand_get_reg_size(self)
        else
          nil
        end
      end

      # Returns the operand's index register size (e.g. in VSIB instructions)
      # @return [Integer, nil] the operand's index registert size or nil if this operand does not hold a index register
      def index_register_size
        if type == :vsib
          convert_size Libevoasm.x64_operand_get_index_reg_size(self)
        else
          nil
        end
      end

      # Returns the operand's memory size (e.g. in R/M instructions)
      # @return [Integer, nil] the operand's memory size or nil if this operand is not a memory operand
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