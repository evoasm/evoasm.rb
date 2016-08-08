require_relative '../test_helper'
require 'evoasm/x64'

module X64
  module MiniTest::Assertions
    include Evoasm

    def assert_disassembles_to(exp_disasm, inst_name, **params)
      exp_disasm.force_encoding('ASCII-8BIT')
      act_disasm = disassemble(@x64.encode(inst_name, params))
      assert_equal exp_disasm, act_disasm
    end

    def assert_assembles_to(exp_asm, inst_name, **params)
      exp_asm.force_encoding('ASCII-8BIT')
      act_asm = assemble(inst_name, **params)
      assert_equal exp_asm, act_asm
    end
  end

  class X64Test < Minitest::Test
    def setup
      @x64 = Evoasm::X64.new
    end

    def disassemble(asm)
      Evoasm::X64.disassemble(asm).first.join(' ')
    end

    def assemble(inst_name, **params)
      @x64.encode(inst_name, params)
    end
  end
end
