require 'evoasm/libevoasm'
require 'evoasm/capstone'
require 'evoasm/x64/instruction'
require 'evoasm/x64/operand'
require 'evoasm/x64/parameters'

module Evoasm
  module X64

    Evoasm.min_log_level = :info
    unless Libevoasm.x64_init
      raise Error.last
    end

    class << self
      def disassemble(assembly, address = nil)
        Evoasm::Capstone.disassemble_x64 assembly, address
      end

      def encode(instruction_name, parameters, basic: false)
        instruction(instruction_name).encode parameters, basic: basic
      end

      def features
        feature_enum_type = Libevoasm.enum_type(:x64_feature)
        arch_info = Libevoasm.arch_info :x64
        features_as_flags = Libevoasm.arch_info_features arch_info
        feature_enum_type.symbol_map.each_with_object([]) do |(k, v), acc|
          acc << k if features_as_flags & (1 << v)
        end
      end

      def instruction(inst_name)
        Instruction.new Libevoasm.x64_inst(inst_name), inst_name
      end

      def instruction_names(*reg_types, operand_types: [:reg, :rm, :imm], search: true, features: nil)
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
            arch_info = Libevoasm.get_arch_info :x64
            Libevoasm.arch_info_get_features arch_info
          else
            feature_enum_type.flags features, shift: true
          end

        op_types_as_flags = op_type_enum_type.flags operand_types, shift: true
        reg_types_as_flags = reg_type_enum_type.flags reg_types, shift: true

        n_insts = inst_id_enum_type[:n_insts]
        array = FFI::MemoryPointer.new :int, n_insts
        len = Libevoasm.x64_insts(flags_as_flags, features_as_flags,
                                   op_types_as_flags, reg_types_as_flags, array)

        instruction_ids = array.read_array_of_type(:int, :read_int, len)

        instruction_ids.map { |e| inst_id_enum_type[e] }
      end

    end
  end
end