require_relative 'test_helper'

module X64
  class EncodingTest < X64Test
    def test_direct
      assert_disassembles_to 'add rax, rbx', :add_r64_rm64,
                             reg0: :a, reg1: :b
      assert_disassembles_to 'add r11, r12', :add_r64_rm64,
                             reg0: :r11, reg1: :r12
      assert_disassembles_to 'add eax, ebx', :add_r32_rm32,
                             reg0: :a, reg1: :b
      assert_disassembles_to 'add ax, bx', :add_r16_rm16,
                             reg0: :a, reg1: :b
    end

    def test_indirect
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

      assert_disassembles_to 'add rax, qword ptr [rbx + rcx*4]', :add_r64_rm64,
                             reg0: :a, reg_base: :b, reg_index: :c, scale: 4
      assert_disassembles_to 'add rax, qword ptr [rbx + rcx]', :add_r64_rm64,
                             reg0: :a, reg_base: :b, reg_index: :c, scale: 1
      assert_disassembles_to 'add rax, qword ptr [rbx + rcx*8]', :add_r64_rm64,
                             reg0: :a, reg_base: :b, reg_index: :c, scale: 8
      assert_disassembles_to 'add r10, qword ptr [r11 + r12*4]', :add_r64_rm64,
                             reg0: :r10, reg_base: :r11, reg_index: :r12, scale: 4
    end

    def test_address_size
      assert_disassembles_to 'add rax, dword ptr [ebx]', :add_r64_rm64,
                             reg0: :a, reg_base: :b, address_size: 32

      assert_disassembles_to 'add eax, dword ptr [ebx]', :add_r32_rm32,
                             reg0: :a, reg_base: :b, address_size: 32
    end

    def test_rex
      assert_disassembles_to 'add rax, rbx', :add_r64_rm64,
                             reg0: :a, reg1: :b, force_rex?: true

      # needs REX (.W), even if not forced
      assert_assembles_to "\x48\x03\xC3", :add_r64_rm64,
                             reg0: :a, reg1: :b, force_rex?: false

      assert_assembles_to "\x48\x03\xC3", :add_r64_rm64,
                          reg0: :a, reg1: :b, force_rex?: true

      # REX.X is free
      assert_assembles_to "\x4A\x03\xC3", :add_r64_rm64,
                          reg0: :a, reg1: :b, rex_x: 0b1

      assert_disassembles_to "add rax, rbx", :add_r64_rm64,
                          reg0: :a, reg1: :b, rex_x: 0b1

      # REX is optional
      assert_disassembles_to "add eax, ebx", :add_r32_rm32,
                             reg0: :a, reg1: :b

      assert_assembles_to "\x03\xC3", :add_r32_rm32,
                          reg0: :a, reg1: :b

      assert_assembles_to "\x40\x03\xC3", :add_r32_rm32,
                          reg0: :a, reg1: :b, force_rex?: true

      assert_disassembles_to "add eax, ebx", :add_r32_rm32,
                             reg0: :a, reg1: :b, force_rex?: true

      # REX.X is free
      assert_assembles_to "\x42\x03\xC3", :add_r32_rm32,
                          reg0: :a, reg1: :b, force_rex?: true, rex_x: 0b1

      # REX.X is free
      assert_assembles_to "\x40\x81\xC0\x10\x00\x00\x00", :add_rm32_imm32,
                          reg0: :a, imm0: 0x10, force_rex?: true

      assert_assembles_to "\x42\x81\xC0\x10\x00\x00\x00", :add_rm32_imm32,
                          reg0: :a, imm0: 0x10, force_rex?: true, rex_x: 0b1

      # REX.R is free (register is encoded in ModRM.rm)
      assert_assembles_to "\x44\x81\xC0\x10\x00\x00\x00", :add_rm32_imm32,
                          reg0: :a, imm0: 0x10, force_rex?: true, rex_r: 0b1

      assert_assembles_to "\x46\x81\xC0\x10\x00\x00\x00", :add_rm32_imm32,
                          reg0: :a, imm0: 0x10, force_rex?: true, rex_r: 0b1, rex_x: 0b1


    end

    def test_byte_reg

      assert_assembles_to "\x40\x02\xC3", :add_r8_rm8,
                          reg0: :a, reg1: :b, force_rex?: true

      assert_assembles_to "\x02\xC3", :add_r8_rm8,
                          reg0: :a, reg1: :b, force_rex?: false

      assert_assembles_to "\x40\x00\xD8", :add_rm8_r8,
                          reg0: :a, reg1: :b, force_rex?: true

      assert_assembles_to "\x00\xD8", :add_rm8_r8,
                          reg0: :a, reg1: :b, force_rex?: false

      %i(add_r8_rm8 add_rm8_r8).each do |inst|
        assert_disassembles_to 'add al, bl', inst,
                               reg0: :a, reg1: :b

        assert_disassembles_to 'add r11b, r12b', inst,
                               reg0: :r11, reg1: :r12

        assert_disassembles_to 'add al, r12b', inst,
                               reg0: :a, reg1: :r12

        assert_disassembles_to 'add al, bl', inst,
                               reg0: :a, reg1: :b, force_rex?: true

        assert_disassembles_to 'add ah, bl', inst,
                               reg0: :a, reg1: :b, reg0_high_byte?: true

        assert_disassembles_to 'add ah, al', inst,
                               reg0: :a, reg1: :a, reg0_high_byte?: true

        assert_disassembles_to 'add ah, bh', inst,
                               reg0: :a, reg1: :b, reg0_high_byte?: true, reg1_high_byte?: true

        assert_disassembles_to 'add al, bh', inst,
                               reg0: :a, reg1: :b, reg0_high_byte?: false, reg1_high_byte?: true

        assert_disassembles_to 'add sil, dil', inst,
                               reg0: :si, reg1: :di, reg0_high_byte?: false, reg1_high_byte?: false

        assert_disassembles_to 'add sil, dil', inst,
                               reg0: :si, reg1: :di

        assert_raises Evoasm::Error do
          @x64.encode :add_r8_rm8, reg0: :si, reg1: :b, reg1_high_byte?: true
        end
      end

      assert_assembles_to "\x40\xb6\x10", :mov_r8_imm8,
                          reg0: :si, imm0: 0x10

      assert_disassembles_to 'mov sil, 0x10', :mov_r8_imm8,
                             reg0: :si, imm0: 0x10

    end

    def test_mi
      assert_disassembles_to 'add rax, 0xa', :add_rm64_imm8,
                             reg0: :a, imm0: 0xa

      assert_disassembles_to 'add qword ptr [rax], 0xa', :add_rm64_imm8,
                             reg_base: :a, imm0: 0xa
    end

    def test_vex_rex
      (0..15).each do |i|
        assert_disassembles_to "vcvttss2si rdi, xmm#{i}", :vcvttss2si_r64_xmmm32,
                               reg0: :di, reg1: :"xmm#{i}"

        assert_disassembles_to "vcvttss2si r12, xmm#{i}", :vcvttss2si_r64_xmmm32,
                               reg0: :r12, reg1: :"xmm#{i}"
      end
    end

    def test_force_long_vex
      assert_assembles_to "\xC5\xF5\xEC\xC2", :vpaddsb_ymm_ymm_ymmm256,
                          reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, force_long_vex?: false
      assert_assembles_to "\xC5\xF5\xEC\xC2", :vpaddsb_ymm_ymm_ymmm256,
                          reg0: :xmm0, reg1: :xmm1, reg2: :xmm2
      assert_assembles_to "\xC4\xE1u\xEC\xC2", :vpaddsb_ymm_ymm_ymmm256,
                          reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, force_long_vex?: true

      assert_disassembles_to 'vpaddsb ymm0, ymm1, ymm2', :vpaddsb_ymm_ymm_ymmm256,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2
      assert_disassembles_to 'vpaddsb ymm0, ymm1, ymm2', :vpaddsb_ymm_ymm_ymmm256,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, force_long_vex?: false
      assert_disassembles_to 'vpaddsb ymm0, ymm1, ymm2', :vpaddsb_ymm_ymm_ymmm256,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, force_long_vex?: true
    end

    def test_vex
      assert_assembles_to "\xC5\xF8\x5A\xCA", :vcvtps2pd_xmm_xmmm64,
                          reg0: :xmm1, reg1: :xmm2
      assert_assembles_to "\xC5\xEA\x5A\xCB", :vcvtss2sd_xmm_xmm_xmmm32,
                          reg0: :xmm1, reg1: :xmm2, reg2: :xmm3
      assert_assembles_to "\xC4\xE3\x79\x1D\xD1\x00", :vcvtps2ph_xmmm64_xmm_imm8,
                          reg0: :xmm1, reg1: :xmm2, imm0: 0x0
      assert_assembles_to "\xC4\xC1\xFA\x2C\xFD", :vcvttss2si_r64_xmmm32,
                          reg0: :di, reg1: :xmm13
    end
  end
end
