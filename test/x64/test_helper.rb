require_relative '../test_helper'
require 'evoasm/x64'

module MiniTest::Assertions
  include Evoasm

  def assert_disassembles_to(disasm, inst_name, **params)
    disasm.force_encoding('ASCII-8BIT')
    assert_equal disasm,
                 Evoasm::X64.disassemble(@x64.encode(inst_name, params)).first.join(' ')
  end

  def assert_assembles_to(asm, inst_name, **params)
    asm.force_encoding('ASCII-8BIT')
    assert_equal asm, @x64.encode(inst_name, params)
  end
end

class X64Test < Minitest::Test
  def setup
    @x64 = Evoasm::X64.new
  end
end

