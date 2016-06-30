require_relative 'test_helper'

class X64Test < Minitest::Test
  def setup
    @x64 = Evoasm::X64.new
    @x64.encode :add_r32_rm32, reg0: :A, reg1: :B
  end

  def test_rm_reg_reg
    assert_disassembles_to 'add rax, rbx', :add_r64_rm64,
      reg0: :A, reg1: :B
    assert_disassembles_to 'add r11, r12', :add_r64_rm64,
      reg0: :R11, reg1: :R12
    assert_disassembles_to 'add eax, ebx', :add_r32_rm32,
      reg0: :A, reg1: :B
    assert_disassembles_to 'add ax, bx', :add_r16_rm16,
      reg0: :A, reg1: :B
  end

  def test_rm_reg_base
    assert_disassembles_to 'add rax, qword ptr [rbx]', :add_r64_rm64,
      reg0: :A, reg_base: :B
    assert_disassembles_to 'add r11, qword ptr [r12]', :add_r64_rm64,
      reg0: :R11, reg_base: :R12
    assert_disassembles_to 'add eax, dword ptr [rbx]', :add_r32_rm32,
      reg0: :A, reg_base: :B
    assert_disassembles_to 'add ax, word ptr [rbx]', :add_r16_rm16,
      reg0: :A, reg_base: :B

    # reg1 should be ignored
    assert_disassembles_to 'add eax, dword ptr [rbx]', :add_r32_rm32,
      reg0: :A, reg1: :C, reg_base: :B
  end

  def test_rm_reg_base32
    assert_disassembles_to 'add rax, dword ptr [ebx]', :add_r64_rm64,
      reg0: :A, reg_base: :B, address_size: 32

    assert_disassembles_to 'add eax, dword ptr [ebx]', :add_r32_rm32,
      reg0: :A, reg_base: :B, address_size: 32
  end

  def test_rm_reg_sib
    assert_disassembles_to 'add rax, qword ptr [rbx + rcx*4]', :add_r64_rm64,
      reg0: :A, reg_base: :B, reg_index: :C, scale: 4
    assert_disassembles_to 'add rax, qword ptr [rbx + rcx]', :add_r64_rm64,
      reg0: :A, reg_base: :B, reg_index: :C, scale: 1
    assert_disassembles_to 'add rax, qword ptr [rbx + rcx*8]', :add_r64_rm64,
      reg0: :A, reg_base: :B, reg_index: :C, scale: 8

    assert_disassembles_to 'add r10, qword ptr [r11 + r12*4]', :add_r64_rm64,
      reg0: :R10, reg_base: :R11, reg_index: :R12, scale: 4

  end

  def test_mi
    assert_disassembles_to 'add rax, 0xa', :add_rm64_imm8,
      reg0: :A, imm0: 0xa

    assert_disassembles_to 'add qword ptr [rax], 0xa', :add_rm64_imm8,
      reg_base: :A, imm0: 0xa
  end

  def test_vex
    assert_assembles_to "\xC5\xF5\xEC\xC2", :vpaddsb_ymm_ymm_ymmm256,
      reg0: :XMM0, reg1: :XMM1, reg2: :XMM2, force_long_vex?: false
    assert_assembles_to "\xC4\xE1u\xEC\xC2", :vpaddsb_ymm_ymm_ymmm256,
      reg0: :XMM0, reg1: :XMM1, reg2: :XMM2, force_long_vex?: true
    assert_disassembles_to 'vpaddsb ymm0, ymm1, ymm2', :vpaddsb_ymm_ymm_ymmm256,
      reg0: :XMM0, reg1: :XMM1, reg2: :XMM2
    assert_disassembles_to 'vpaddsb ymm0, ymm1, ymm2', :vpaddsb_ymm_ymm_ymmm256,
      reg0: :XMM0, reg1: :XMM1, reg2: :XMM2, force_long_vex?: true

    assert_assembles_to "\xC5\xF5\xEC\xC2", :vpaddsb_ymm_ymm_ymmm256,
      reg0: :XMM0, reg1: :XMM1, reg2: :XMM2
    assert_disassembles_to 'vpaddusb xmm0, xmm1, xmm2', :vpaddusb_xmm_xmm_xmmm128,
      reg0: :XMM0, reg1: :XMM1, reg2: :XMM2
    assert_assembles_to "\xC5\xF8\x5A\xCA", :vcvtps2pd_xmm_xmmm64,
      reg0: :XMM1, reg1: :XMM2
    assert_assembles_to "\xC5\xEA\x5A\xCB", :vcvtss2sd_xmm_xmm_xmmm32,
      reg0: :XMM1, reg1: :XMM2, reg2: :XMM3

    assert_assembles_to "\xC4\xE3\x79\x1D\xD1\x00", :vcvtps2ph_xmmm64_xmm_imm8,
      reg0: :XMM1, reg1: :XMM2, imm0: 0x0
  end

end
