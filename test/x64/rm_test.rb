require_relative 'test_helper'

class RMTest < X64Test
  def test_reg_reg
    assert_disassembles_to 'add rax, rbx', :add_r64_rm64,
                           reg0: :a, reg1: :b
    assert_disassembles_to 'add r11, r12', :add_r64_rm64,
                           reg0: :r11, reg1: :r12
    assert_disassembles_to 'add eax, ebx', :add_r32_rm32,
                           reg0: :a, reg1: :b
    assert_disassembles_to 'add ax, bx', :add_r16_rm16,
                           reg0: :a, reg1: :b
  end

  def test_reg_base
    assert_disassembles_to 'add rax, qword ptr [rbx]', :add_r64_rm64,
                           reg0: :a, reg_base: :b
    assert_disassembles_to 'add r11, qword ptr [r12]', :add_r64_rm64,
                           reg0: :r11, reg_base: :r12
    assert_disassembles_to 'add eax, dword ptr [rbx]', :add_r32_rm32,
                           reg0: :a, reg_base: :b
    assert_disassembles_to 'add ax, word ptr [rbx]', :add_r16_rm16,
                           reg0: :a, reg_base: :b

    # reg1 should be ignored
    assert_disassembles_to 'add eax, dword ptr [rbx]', :add_r32_rm32,
                           reg0: :a, reg1: :c, reg_base: :b
  end

  def test_reg_base32
    assert_disassembles_to 'add rax, dword ptr [ebx]', :add_r64_rm64,
                           reg0: :a, reg_base: :b, address_size: 32

    assert_disassembles_to 'add eax, dword ptr [ebx]', :add_r32_rm32,
                           reg0: :a, reg_base: :b, address_size: 32
  end

  def test_reg_sib
    assert_disassembles_to 'add rax, qword ptr [rbx + rcx*4]', :add_r64_rm64,
                           reg0: :a, reg_base: :b, reg_index: :c, scale: 4
    assert_disassembles_to 'add rax, qword ptr [rbx + rcx]', :add_r64_rm64,
                           reg0: :a, reg_base: :b, reg_index: :c, scale: 1
    assert_disassembles_to 'add rax, qword ptr [rbx + rcx*8]', :add_r64_rm64,
                           reg0: :a, reg_base: :b, reg_index: :c, scale: 8

    assert_disassembles_to 'add r10, qword ptr [r11 + r12*4]', :add_r64_rm64,
                           reg0: :r10, reg_base: :r11, reg_index: :r12, scale: 4

  end

end
