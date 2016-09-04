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


    class InstructionTest
      attr_reader :instruction

      class Operand
        attr_reader :operand

        SKIP_IMPLICIT_XMM0_INSTRUCTION_NAMES = %i(
          blendvpd_xmm_xmmm128_xmm0
          blendvps_xmm_xmmm128_xmm0
          pblendvb_xmm_xmmm128_xmm0
        ).freeze

        REGISTERS = {
          a: {
             8 => 'al',
            16 => 'ax',
            32 => 'eax',
            64 => 'rax'
          },
          b: {
            8  => 'bl',
            16 => 'bx',
            32 => 'ebx',
            64 => 'rbx'
          },
          c: {
            8  => 'cl',
            16 => 'cx',
            32 => 'ecx',
            64 => 'rcx'
          },
        }.freeze

        def initialize(operand, ass)
          @operand = operand
          @
        end

        def disassembly
          return nil unless operand.mnemonic?
          return parameter_disassembly if operand.parameter
          return implicit_disassembly if operand.implicit?
          return memory_disassembly if operand.type == :mem
          raise
        end

        private

        def memory_disassembly
          parameters[:reg_base] = gp_regs[:reg0][0]
          p operand.size
          exp_disasm_ops << "#{ptrs[:reg0].fetch(index)}"
        end

        def implicit_disassembly
          if operand.type == :imm
            operand.immediate.to_s
          elsif operand.type == :reg && operand.register == :xmm0
            'xmm0' unless skip_implicit_xmm0?
          else
            REGISTERS.fetch(operand.register).fetch(operand.size)
          end
        end

        def skip_implicit_xmm0?
          SKIP_IMPLICIT_XMM0_INSTRUCTION_NAMES.include? operand.instruction.name
        end

        def parameter_disassembly
          parameter_name = operand.parameter.name

          case parameter_name
          when :reg0, :reg1, :reg2, :reg3
            case operand.register_type
            when :gp
              parameters[parameter_name] = gp_regs[parameter_name][0]
              op = gp_regs[parameter_name].fetch(index)
              exp_disasm_ops << op
            when :xmm
              parameters[parameter_name] = xmm_regs[parameter_name]
              disasm_op = xmm_regs[parameter_name].to_s
              if operand.size == 256
                disasm_op.sub! 'xmm', 'ymm'
              end
              exp_disasm_ops << disasm_op
            else
              raise "unexpected register type '#{operand.register_type}'"
            end
          when :imm, :imm0, :imm1, :rel
            parameters[parameter_name] = imms[parameter_name]
            unless parameter_name == :rel
              exp_disasm_ops << "0x#{imms[parameter_name].to_s(16)}"


              if parameters.key? :rel
                exp_disasm_ops << "0x#{(parameters[:rel] + asm.size).to_s(16)}"
              end
            end
          end
          # code here
        end
      end

      def initialize(test_class, instruction, basic: false)
        @test_class = test_class
        @instruction = instruction
        @basic = basic
      end

      def disassembly
        mnemonics.map do |mnemonic|
          "#{mnemonic.downcase} #{expected_disassembly_operands.join(', ')}"
        end
      end

      def mnemonics
        if instruction.name == :mov_r64_imm64
          %w(movabs)
        else
          instruction.mnemonics
        end
      end

      def run
        # Capstone prints rm operand last
        expected_operands = instruction.operands.map { |operand| Operand.new operand }
        expected_operands.reverse! if instruction.name =~ /^test_rm\d+_r\d+/

        expected_disassemblys = mnemonics.map do |mnemonic|
          "#{mnemonic.downcase} #{expected_operands.map(&:disassembly).join(', ')}"
        end
        assert_includes expected_disassemblys, disassemble(asm)
      end

      def basic?
        @basic
      end

      def define!
        run_method = method(:run)
        @test_class.send :define_method, test_method_name do
          run_method.call
        end
      end

      private

      def test_method_name
        :"test_#{instruction.name}"
      end
    end

    Evoasm::Libevoasm.enum_type(:x64_inst_id).symbols.each do |instruction_name|
      # Capstone uses pseudo-mnemonics, tested separately
      next if SIMD_CMP_INST_NAMES.include? instruction_name

      # Capstone does not like these for some reason, test separately
      next if NOP_INST_NAMES.include? instruction_name
      next if XCHG_IMPLICIT_INST_NAMES.include? instruction_name

      instruction = Evoasm::X64.instruction instruction_name
      instruction_test = InstructionTest.new self, instruction
      instruction_test.define!
    end
  end
end
