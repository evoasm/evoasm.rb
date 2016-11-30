require 'evoasm/test'

Evoasm.log_level = :info
require 'evoasm/x64'

module Evoasm
  class X64Test < Minitest::Test
    self.make_my_diffs_pretty!

    def test_features
      features = Evoasm::X64.features
      refute_empty features
      assert features.all? { |feature, _| feature.is_a? Symbol }

      if RUBY_PLATFORM =~ /linux/
        cpu_info = File.read '/proc/cpuinfo'

        feature_keys =[:cx8, :cmov, :mmx, :sse, :sse2, :pclmulqdq, :ssse3, :fma, :cx16, :sse4_1,
                       :sse4_2, :movbe, :popcnt, :aes, :avx, :f16c, :rdrand, :lahf_lm, :bmi1, :avx2, :bmi2]

        cpu_info_features = feature_keys.map do |feature|
          [feature, !!(cpu_info =~ /\b#{feature}\b/)]
        end.sort.to_h

        assert_equal cpu_info_features, features.sort.select { |feature, support| feature_keys.include? feature}.to_h
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

      search_insts = Evoasm::X64.instruction_names :xmm, :gp, :rflags
      assert_equal search_insts, Evoasm::X64.instruction_names(:xmm, :gp, :rflags, operand_types: [:reg, :imm, :rm])
      refute_empty search_insts
      refute_includes search_insts, :jmp_rel32
      refute_includes search_insts, :call_rm32
      assert_includes search_insts, :xor_rax_imm32
      assert_includes search_insts, :vfmadd213pd_xmm_xmm_xmmm128
      assert_empty search_insts.grep(/rdrand/)
    end
  end
end
