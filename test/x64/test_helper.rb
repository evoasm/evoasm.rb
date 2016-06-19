require_relative '../test_helper'

require 'evoasm'

module MiniTest::Assertions
  include Evoasm

  def assert_disassembles_to(disasm, inst_name, **params)
    assert_equal disasm,
        Evoasm::X64.disassemble(@x64.encode(inst_name, params)).first
  end

  def assert_assembles_to(asm, inst_name, **params)
    assert_equal asm, @x64.encode(inst_name, params)
  end
end

Array.infect_an_assertion :assert_disassembles_to, :must_disassemble_to
Array.infect_an_assertion :assert_assembles_to, :must_assemble_to
