require 'test_helper'
require 'evoasm/x64'

module X64Helper
  def assert_disassembles_to(exp_disasm, instruction_name, **parameters)
    exp_disasm.force_encoding('ASCII-8BIT')
    act_disasm = disassemble(Evoasm::X64.encode(instruction_name, parameters))
    assert_equal exp_disasm, act_disasm
  end

  def assert_assembles_to(exp_asm, inst_name, **params)
    exp_asm.force_encoding('ASCII-8BIT')
    act_asm = assemble(inst_name, **params)
    assert_equal exp_asm, act_asm
  end

  def disassemble(asm)
    Evoasm::X64.disassemble(asm).first.join(' ')
  end

  def assemble(instruction_name, **parameters)
    Evoasm::X64.encode(instruction_name, parameters)
  end
end
