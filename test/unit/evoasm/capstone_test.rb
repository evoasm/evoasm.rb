require 'evoasm/test'
require 'evoasm/capstone'

class CapstoneTest < Minitest::Test
  def test_disassemble_x64

    asm = "\x55\x48\x8b\x05\xb8\x13\x00\x00"
    inst1 = ['push', 'rbp']
    inst2 = ['mov', 'rax, qword ptr [rip + 0x13b8]']

    assert_equal [inst1, inst2],
                 Evoasm::Capstone.disassemble_x64(asm)

    assert_equal [[0x80, *inst1], [0x81, *inst2]],
                 Evoasm::Capstone.disassemble_x64(asm, 0x80)

  end
end
