require 'evoasm/libevoasm'
require 'evoasm/capstone'
require 'evoasm/x64/instruction'
require 'evoasm/x64/operand'
require 'evoasm/x64/parameters'

module Evoasm
  module X64
    unless Libevoasm.x64_init
      raise Error.last
    end

    class << self
      # Disassembles x86-64 machine code
      # @param assembly [String] assembly
      # @param address [Integer] optional address to show in the disassembly
      def disassemble(assembly, address = nil)
        Evoasm::Capstone.disassemble_x64 assembly, address
      end

      # Encodes a x86-64 machine instruction
      # @param instruction_name [Symbol] the name of the instruction
      # @param parameters [X64::Parameters, Hash] the instruction parameters
      # @param buffer [Buffer] the buffer to emit to, if omitted, the encoded instruction is retured as string
      # @param basic [Boolean] whether to use the basic encoder
      # @return [String, nil] the encoded machine code as string, or nil if a buffer was provided
      def encode(instruction_name, parameters, buffer = nil, basic: false)
        instruction(instruction_name).encode parameters, buffer, basic: basic
      end

      # @return [Array<Symbol>] a list of available registers
      def registers
        Libevoasm.enum_type(:x64_reg_id).symbols[0..-2]
      end

      # @return [Array<Symbol>] the list of supported CPU features (obtained via CPUID)
      def features
        feature_enum_type = Libevoasm.enum_type(:x64_feature)
        arch_info = Libevoasm.get_arch_info :x64
        features_as_flags = Libevoasm.arch_info_get_features arch_info
        feature_enum_type.symbol_map.each_with_object({}) do |(k, v), features|
          next if k == :none
          supported = (features_as_flags & (1 << v)) != 0
          features[k] = supported
        end
      end

      # Gives an {Instruction} object for the given instruction name.
      # @param instruction_name [Symbol] instruction name
      # @return [Instruction]
      def instruction(instruction_name)
        Instruction.new Libevoasm.x64_inst(instruction_name), instruction_name
      end

      # Emits a stack frame for the given ABI
      # @param abi [Symbol] the ABI to use
      # @param buffer [Buffer] the buffer to emit to
      # @return [void]
      def emit_stack_frame(abi = :sysv, buffer)
        unless Libevoasm.x64_emit_func_prolog abi, buffer
          raise Error.last
        end

        yield

        unless Libevoasm.x64_emit_func_epilog abi, buffer
          raise Error.last
        end
      end

      # Gives a list of instructions
      # @param reg_types [Array] restrict to given register types (e.g. +:gp+ for general-purpose registers)
      # @param operand_types [Array<Symbol>] restrict to instructions whose operands are of the specified types
      # @param useless [Bool] whether to include useless instructions
      # @param basic [Bool] restrict to instructions supported by the basic encoder
      # @param features [Array<Symbol>] only give instructions covered by the specified feature set
      # @return [Array<Symbol>] array of instruction names
      def instruction_names(*reg_types, operand_types: [:reg, :rm, :imm], useless: false, basic: true, features: nil)
        inst_id_enum_type = Libevoasm.enum_type(:x64_inst_id)
        feature_enum_type = Libevoasm.enum_type(:x64_feature)
        insts_flags_enum_type = Libevoasm.enum_type(:x64_insts_flags)
        op_type_enum_type = Libevoasm.enum_type(:x64_operand_type)
        reg_type_enum_type = Libevoasm.enum_type(:x64_reg_type)

        flags = []

        flags << :include_useless if useless
        flags << :only_basic if basic
        flags_as_flags = insts_flags_enum_type.flags flags, shift: false

        features_as_flags =
          if features.nil?
            arch_info = Libevoasm.get_arch_info :x64
            Libevoasm.arch_info_get_features arch_info
          else
            feature_enum_type.flags features, shift: true
          end

        op_types_as_flags = op_type_enum_type.flags operand_types, shift: true
        reg_types_as_flags = reg_type_enum_type.flags reg_types, shift: true

        n_insts = inst_id_enum_type[:none]
        array = FFI::MemoryPointer.new :int, n_insts
        len = Libevoasm.x64_insts(flags_as_flags, features_as_flags,
                                   op_types_as_flags, reg_types_as_flags, array)

        instruction_ids = array.read_array_of_type(:int, :read_int, len)

        instruction_ids.map { |e| inst_id_enum_type[e] }
      end

    end
  end
end