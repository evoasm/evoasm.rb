require_relative 'test_helper'

class VEXTest < X64Test

  def test_rex
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

  def test_encoding
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
