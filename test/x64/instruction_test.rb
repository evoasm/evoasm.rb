require_relative 'test_helper'

module X64
  class InstructionTest < X64Test
    def setup
      super
      @instruction_add = @x64.instruction :add_rm64_imm8
      @instruction_cmov = @x64.instruction :cmovae_cmovnb_cmovnc_r64_rm64
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

      assert_equal :rm, operands[0].parameter_name
      assert operands[0].explicit?
      assert_equal :gp, operands[0].register_type
      assert_nil operands[0].register
      assert_equal :reg0, operands[0].parameter.name
      assert_equal 64, operands[0].size

      assert_equal :imm, operands[1].parameter_names
      assert operands[1].explicit?
      assert_nil operands[1].register_type
      assert_nil operands[1].register
      assert_equal :imm0, operands[1].parameter.name
      assert_equal 8, operands[1].size

      refute_nil @instruction_add.parameters.find(operands[0].parameter)
    end

    def test_parameters
      parameters = @instruction_add.parameters.map(&:name)
      assert_includes parameters, :reg0
      assert_includes parameters, :imm0

      domain = @instruction_add.parameters[1].domain
      assert_kind_of Range, domain
      assert_equal -128, domain.min
      assert_equal 127, domain.max
    end

    def test_encode
      assert_equal "\x48\x83\xC0\x0a".force_encoding('ASCII-8BIT'), @instruction_add.encode(reg0: :a, imm0: 0xa)
    end
  end
end