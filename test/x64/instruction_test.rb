require_relative 'test_helper'

module X64
  class InstructionTest < X64Test
    def setup
      @instruction_add = Evoasm::X64.instruction :add_rm64_imm8
      @instruction_cmov = Evoasm::X64.instruction :cmovae_r64_rm64
    end

    def test_name
      assert_equal :add_rm64_imm8, @instruction_add.name
    end

    def test_mnemonic
      assert_equal 'ADD', @instruction_add.mnemonic
      assert_equal 'CMOVAE', @instruction_cmov.mnemonic
      assert_equal %w(CMOVAE CMOVNB CMOVNC), @instruction_cmov.mnemonics
    end

    def test_operands
      operands = @instruction_add.operands

      assert_equal :rm, operands[0].type
      assert operands[0].explicit?
      assert_equal :gp, operands[0].register_type
      assert_nil operands[0].register
      assert_equal :reg0, operands[0].parameter.name
      assert_equal 64, operands[0].size

      assert_equal :imm, operands[1].type
      assert operands[1].explicit?
      assert_nil operands[1].register_type
      assert_nil operands[1].register
      assert_equal :imm0, operands[1].parameter.name
      assert_equal 8, operands[1].size

      refute_nil @instruction_add.parameters.find(operands[0].parameter)
    end

    def test_parameters
      reg0_parameter = @instruction_add.parameters.find do |parameter|
        parameter.name == :reg0
      end
      refute_nil reg0_parameter

      imm_parameter = @instruction_add.parameters.find do |parameter|
        parameter.name == :imm0
      end
      refute_nil imm_parameter

      imm_domain = imm_parameter.domain
      assert_kind_of Evoasm::Domain, imm_domain
      assert_equal :int8, imm_domain.type
      assert_equal 127, imm_domain.max
      assert_equal -128, imm_domain.min
    end
  end
end