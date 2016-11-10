require 'evoasm/parameter'

module Evoasm
  module X64
    class Instruction < FFI::Pointer
      class Parameter < Evoasm::Parameter
        def name
          Libevoasm.enum_type(:x64_param_id).find id
        end
      end

      attr_reader :name

      def initialize(ptr, name)
        super(ptr)
        @name = name
      end

      def mnemonics
        Libevoasm.x64_inst_get_mnem(self).split('/')
      end

      def mnemonic
        mnemonics.first
      end

      def operand(index)
        Operand.new Libevoasm.x64_inst_get_operand(self, index), self
      end

      def operands
        n_operands = Libevoasm.x64_inst_get_n_operands self
        Array.new(n_operands) do |index|
          operand index
        end
      end

      def parameters
        n_params = Libevoasm.x64_inst_get_n_params self
        Array.new(n_params) do |param_index|
          Parameter.new Libevoasm.x64_inst_get_param(self, param_index)
        end
      end

      def basic?
        Libevoasm.x64_inst_is_basic(self)
      end

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