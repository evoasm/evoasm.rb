require_relative 'test_helper'

module X64
  class InstructionsTest < X64Test
    def setup
      super
    end

    def self.test_order
      :alpha
    end

    def test_simd_cmp
      assert_disassembles_to 'cmpeqpd xmm0, xmm1', :cmppd_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 0

      assert_disassembles_to 'cmpeqps xmm0, xmm1', :cmpps_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 0

      assert_disassembles_to 'cmpeqsd xmm0, xmm1', :cmpsd_xmm_xmmm64_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 0

      assert_disassembles_to 'cmpeqss xmm0, xmm1', :cmpss_xmm_xmmm32_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 0


      assert_disassembles_to 'vcmpeqpd xmm0, xmm1, xmm2', :vcmppd_xmm_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0

      assert_disassembles_to 'vcmpeqps xmm0, xmm1, xmm2', :vcmpps_xmm_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0

      assert_disassembles_to 'vcmpeqsd xmm0, xmm1, xmm2', :vcmpsd_xmm_xmm_xmmm64_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0

      assert_disassembles_to 'vcmpeqss xmm0, xmm1, xmm2', :vcmpss_xmm_xmm_xmmm32_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0


      assert_disassembles_to 'vcmpeqpd ymm0, ymm1, ymm2', :vcmppd_ymm_ymm_ymmm256_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0

      assert_disassembles_to 'vcmpeqps ymm0, ymm1, ymm2', :vcmpps_ymm_ymm_ymmm256_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0


      assert_disassembles_to 'cmpordpd xmm0, xmm1', :cmppd_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 7

      assert_disassembles_to 'cmpordps xmm0, xmm1', :cmpps_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 7

      assert_disassembles_to 'cmpordsd xmm0, xmm1', :cmpsd_xmm_xmmm64_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 7

      assert_disassembles_to 'cmpordss xmm0, xmm1', :cmpss_xmm_xmmm32_imm8,
                             reg0: :xmm0, reg1: :xmm1, imm0: 7


      assert_disassembles_to 'vcmpordpd xmm0, xmm1, xmm2', :vcmppd_xmm_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 7

      assert_disassembles_to 'vcmpordps xmm0, xmm1, xmm2', :vcmpps_xmm_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 7

      assert_disassembles_to 'vcmpordsd xmm0, xmm1, xmm2', :vcmpsd_xmm_xmm_xmmm64_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 7

      assert_disassembles_to 'vcmpordss xmm0, xmm1, xmm2', :vcmpss_xmm_xmm_xmmm32_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 7


      assert_disassembles_to 'vcmpordpd ymm0, ymm1, ymm2', :vcmppd_ymm_ymm_ymmm256_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 7


      assert_disassembles_to 'vcmpordps ymm0, ymm1, ymm2', :vcmpps_ymm_ymm_ymmm256_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 7


      assert_disassembles_to 'vcmptrue_uspd xmm0, xmm1, xmm2', :vcmppd_xmm_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0x1f

      assert_disassembles_to 'vcmptrue_usps xmm0, xmm1, xmm2', :vcmpps_xmm_xmm_xmmm128_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0x1f

      assert_disassembles_to 'vcmptrue_ussd xmm0, xmm1, xmm2', :vcmpsd_xmm_xmm_xmmm64_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0x1f

      assert_disassembles_to 'vcmptrue_uspd ymm0, ymm1, ymm2', :vcmppd_ymm_ymm_ymmm256_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0x1f

      assert_disassembles_to 'vcmptrue_usps ymm0, ymm1, ymm2', :vcmpps_ymm_ymm_ymmm256_imm8,
                             reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, imm0: 0x1f

    end

    def test_nop
      assert_assembles_to "\x66\x0F\x1F\xC0", :nop_rm16, reg0: :a
      assert_assembles_to "\x0F\x1F\xC0", :nop_rm32, reg0: :a
    end

    def test_xchg_implicit
      assert_assembles_to "\x66\x93", :xchg_ax_r16, reg0: :b
      assert_assembles_to "\x93", :xchg_eax_r32, reg0: :b
      assert_assembles_to "\x48\x93", :xchg_rax_r64, reg0: :b
    end

    SIMD_CMP_INST_NAMES = %i(
      vcmpps_xmm_xmm_xmmm128_imm8
      vcmppd_xmm_xmm_xmmm128_imm8
      vcmpps_ymm_ymm_ymmm256_imm8
      vcmppd_ymm_ymm_ymmm256_imm8
      vcmpsd_xmm_xmm_xmmm64_imm8
      vcmpss_xmm_xmm_xmmm32_imm8
      cmpps_xmm_xmmm128_imm8
      cmppd_xmm_xmmm128_imm8
      cmpsd_xmm_xmmm64_imm8
      cmpss_xmm_xmmm32_imm8
    ).freeze

    NOP_INST_NAMES = %i(
      nop_rm16
      nop_rm32
    ).freeze

    XCHG_IMPLICIT_INST_NAMES = %i(
      xchg_ax_r16
      xchg_eax_r32
      xchg_rax_r64
    )

    SKIP_IMPLICIT_XMM0_INST_NAMES = %i(
      blendvpd_xmm_xmmm128_xmm0
      blendvps_xmm_xmmm128_xmm0
      pblendvb_xmm_xmmm128_xmm0
    ).freeze

    Evoasm::Libevoasm.enum_type(:x64_inst_id).symbols.each do |inst_name|
      # Capstone uses pseudo-mnemonics, tested separately
      next if SIMD_CMP_INST_NAMES.include? inst_name

      # Capstone does not like these for some reason, test separately
      next if NOP_INST_NAMES.include? inst_name
      next if XCHG_IMPLICIT_INST_NAMES.include? inst_name

      define_method :"test_#{inst_name}" do
        instruction = @x64.instruction inst_name
        exp_disasm_ops = []
        gp_regs = {
          reg0: [:a, 'al', 'ax', 'eax', 'rax'],
          reg1: [:c, 'cl', 'cx', 'ecx', 'rcx'],
          reg2: [:b, 'bl', 'bx', 'ebx', 'rbx']
        }
        xmm_regs = {reg0: :xmm0, reg1: :xmm1, reg2: :xmm2, reg3: :xmm3}
        imms = {imm0: 0x12, imm1: 0x34, rel: 0x13}
        params = {}


        p [inst_name]

        instruction.operands.each do |operand|
          if operand.register_type == :gp
            index = Math.log2(operand.size).ceil.to_i - 2
          end

          if operand.mnemonic?
            if operand.parameter
              param_name = operand.parameter.name

              p param_name
              case param_name
              when :reg0, :reg1, :reg2, :reg3
                  case operand.register_type
                  when :gp
                    params[param_name] = gp_regs[param_name][0]
                    op = gp_regs[param_name].fetch(index)
                    exp_disasm_ops << op
                  when :xmm
                    params[param_name] = xmm_regs[param_name]
                    disasm_op = xmm_regs[param_name].to_s
                    if operand.size == 256
                      disasm_op.sub! 'xmm', 'ymm'
                    end
                    exp_disasm_ops << disasm_op
                  else
                    raise "unexpected register type '#{operand.register_type}'"
                  end
              when :imm0, :imm1, :rel
                params[param_name] = imms[param_name]
                unless param_name == :rel
                  exp_disasm_ops << "0x#{imms[param_name].to_s(16)}"
                end
              end
            elsif operand.implicit?
              if operand.register == :xmm0
                # for these, Capstone does not list the implicit operand
                next if SKIP_IMPLICIT_XMM0_INST_NAMES.include? inst_name
                exp_disasm_ops << 'xmm0'
              elsif operand.type == :imm
                exp_disasm_ops << operand.immediate
              else
                p operand.register
                regs = gp_regs.find { |k, v| v[0] == operand.register }[1]
                exp_disasm_ops << regs.fetch(index).to_s
              end
            elsif operand.type == :vsib
              raise
            elsif operand.type == :mem
              params[:reg_base] = gp_regs[:reg0][0]
              exp_disasm_ops << "[#{gp_regs[:reg0].fetch(index)}]"
            end
          end
        end

        p [inst_name, params]
        asm = assemble(inst_name, **params)

        if params.key? :rel
          exp_disasm_ops << "0x#{(params[:rel] + asm.size).to_s(16)}"
        end

        mnems =
          if inst_name == :mov_r64_imm64
            %w(movabs)
          else
            instruction.mnemonics
          end

        # Capstone print rm operand last
        exp_disasm_ops.reverse! if inst_name =~ /^test_rm\d+_r\d+/

        exp_asms = mnems.map do |mnem|
          "#{mnem.downcase} #{exp_disasm_ops.join(', ')}"
        end

        p [inst_name, exp_asms.first, params, asm]
        assert_includes exp_asms, disassemble(asm)
      end
    end
  end
end
