require_relative 'test_helper'

class GeneralTest < X64Test
  def setup
    @x64 = Evoasm::X64.new
  end

  def test_features
    features = @x64.features
    refute_empty features
    assert features.all? { |i| i.is_a? Symbol }
    if RUBY_PLATFORM =~ /linux/
      cpu_info = File.read '/proc/cpuinfo'
      [:cx8, :cmov, :mmx, :sse, :sse2, :pclmulqdq, :ssse3, :fma, :cx16, :sse4_1,
       :sse4_2, :movbe, :popcnt, :aes, :avx, :f16c, :rdrand, :lahf_lm, :bmi1, :avx2, :bmi2].each do |feature|
        assert_equal features.include?(feature), !!(cpu_info =~ /\b#{feature}\b/)
      end
    end
  end

  def test_instructions
    search_insts = @x64.instructions :xmm, :gp, :rflags, search: true
    assert_equal search_insts, @x64.instructions(:xmm, :gp, :rflags, search: true, operand_types: [:reg, :imm, :rm])
    refute_empty search_insts
    refute_includes search_insts, :jmp_rel32
    refute_includes search_insts, :call_rm32
    assert_includes search_insts, :xor_rax_imm32
    assert_includes search_insts, :vfmadd213pd_xmm_xmm_xmmm128

    gp_insts = @x64.instructions :gp, :rflags
    refute_empty gp_insts
    assert_includes gp_insts, :xor_rax_imm32
    refute_includes gp_insts, :vfmadd213pd_xmm_xmm_xmmm128

    xmm_insts = @x64.instructions :xmm
    refute_empty xmm_insts
    refute_includes xmm_insts, :jmp_rel32
    refute_includes xmm_insts, :xor_rax_imm32
    assert_includes xmm_insts, :vfmadd213pd_xmm_xmm_xmmm128
  end

  def test_mi
    assert_disassembles_to 'add rax, 0xa', :add_rm64_imm8,
                           reg0: :a, imm0: 0xa

    assert_disassembles_to 'add qword ptr [rax], 0xa', :add_rm64_imm8,
                           reg_base: :a, imm0: 0xa
  end
end
