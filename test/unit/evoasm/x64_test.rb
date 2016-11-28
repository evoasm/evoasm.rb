require 'evoasm/test'
require 'evoasm/x64'

module Evoasm
  class X64Test < Minitest::Test

    def test_features
      features = Evoasm::X64.features
      refute_empty features
      assert features.all? { |feature, _| feature.is_a? Symbol }
      if RUBY_PLATFORM =~ /linux/
        cpu_info = File.read '/proc/cpuinfo'
        [:cx8, :cmov, :mmx, :sse, :sse2, :pclmulqdq, :ssse3, :fma, :cx16, :sse4_1,
         :sse4_2, :movbe, :popcnt, :aes, :avx, :f16c, :rdrand, :lahf_lm, :bmi1, :avx2, :bmi2].each do |feature|
          assert features[feature] == !!(cpu_info =~ /\b#{feature}\b/),
                 "availability of feature '#{feature}' does not match cpuinfo"
        end
      end
    end

    def test_instructions
      gp_insts = Evoasm::X64.instruction_names :gp, :rflags
      refute_empty gp_insts
      assert_includes gp_insts, :xor_rax_imm32
      refute_includes gp_insts, :vfmadd213pd_xmm_xmm_xmmm128
      refute_includes gp_insts, :cvtsd2si_r64_xmmm64

      xmm_insts = Evoasm::X64.instruction_names :xmm
      refute_empty xmm_insts
      refute_includes xmm_insts, :jmp_rel32
      refute_includes xmm_insts, :xor_rax_imm32
      assert_includes xmm_insts, :vfmadd213pd_xmm_xmm_xmmm128

      search_insts = Evoasm::X64.instruction_names :xmm, :gp, :rflags, search: true
      assert_equal search_insts, Evoasm::X64.instruction_names(:xmm, :gp, :rflags, search: true, operand_types: [:reg, :imm, :rm])
      refute_empty search_insts
      refute_includes search_insts, :jmp_rel32
      refute_includes search_insts, :call_rm32
      assert_includes search_insts, :xor_rax_imm32
      assert_includes search_insts, :vfmadd213pd_xmm_xmm_xmmm128
      assert_empty search_insts.grep(/rdrand/)
    end
  end
end
