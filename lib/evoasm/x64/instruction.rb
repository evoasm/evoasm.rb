require 'evoasm/parameter'

module Evoasm
  module X64
    # Represents an x86-64 instruction
    class Instruction < FFI::Pointer
      class Parameter < Evoasm::Parameter
        def name
          Libevoasm.enum_type(:x64_param_id).find id
        end
      end

      # @return [Symbol] the instruction's name
      attr_reader :name

      # @!visibility private
      def initialize(ptr, name)
        super(ptr)
        @name = name
      end

      # Gives a list of instruction mnemonics
      # @return [Array<String>] mnemonics
      def mnemonics
        Libevoasm.x64_inst_get_mnem(self).split('/')
      end

      # Gives the preferred instruction mnemonic
      # @return [String] the mnemonics
      # @see #mnemonics
      def mnemonic
        mnemonics.first
      end

      # Gives the operand at the specified index
      # @return [Operand] the operand
      def operand(index)
        Operand.new Libevoasm.x64_inst_get_operand(self, index), self
      end

      # Gives the instruction's operands
      # @return [Array<Operand>] the operands
      def operands
        n_operands = Libevoasm.x64_inst_get_n_operands self
        Array.new(n_operands) do |index|
          operand index
        end
      end

      # Gives this instruction's parameters
      # @return [Array<Instruction::Parameter>] the parameters
      def parameters
        n_params = Libevoasm.x64_inst_get_n_params self
        Array.new(n_params) do |param_index|
          Parameter.new Libevoasm.x64_inst_get_param(self, param_index)
        end
      end

      # Returns whether this instruction is encodable with the basic encoder
      # @return [Bool]
      def basic?
        Libevoasm.x64_inst_is_basic(self)
      end

      # Encodes the instruciton with the given parameters
      # @param parameters [X64::Parameters] parameters
      # @param buffer [Buffer] the buffer to emit to
      # @param basic [Bool] whether the basic encoder should be used
      # @return [void]
      def encode(parameters, buffer = nil, basic: false)
        if basic && !basic?
          raise ArgumentError, 'instruction does not support basic mode'
        end

        buf_ref = Libevoasm.buf_ref_alloc

        if buffer
          Libevoasm.buf_to_buf_ref buffer, buf_ref
        else
          data = FFI::MemoryPointer.new :uint8, 32
          len_ptr = FFI::MemoryPointer.new :size_t, 1
          Libevoasm.buf_ref_init buf_ref, data, len_ptr
        end

        parameters = Parameters.for(parameters, basic: basic)

        success =
          if basic
            Libevoasm.x64_inst_enc_basic self, parameters, buf_ref
          else
            Libevoasm.x64_inst_enc self, parameters, buf_ref
          end

        Libevoasm.buf_ref_free buf_ref

        if success
          unless buffer
            len = len_ptr.read_size_t
            data.read_string len
          end
        else
          raise Error.last
        end
      end
    end
  end
end