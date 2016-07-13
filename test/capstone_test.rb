require_relative 'test_helper'

require 'evoasm/capstone'

class CapstoneTest < Minitest::Test
  def test_disassemble_x64
    assert_equal [[0, "push", "rbp"], [1, "mov", "rax, qword ptr [rip + 0x13b8]"]], Evoasm::Capstone.disassemble_x64("\x55\x48\x8b\x05\xb8\x13\x00\x00")
  end
end
