require_relative 'test_helper'

module X64
  class InstructionEncodingTest < X64Test
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

    def test_cmps
      assert_assembles_to "\xA6", :cmpsb
      assert_assembles_to "\x66\xA7", :cmpsw
      assert_assembles_to "\xA7", :cmpsd
      assert_assembles_to "\x48\xA7", :cmpsq
    end

    def test_lods
      assert_assembles_to "\xAC", :lodsb
      assert_assembles_to "\x66\xAD", :lodsw
      assert_assembles_to "\xAD", :lodsd
      assert_assembles_to "\x48\xAD", :lodsq
    end

    def test_movs
      assert_assembles_to "\xA4", :movsb
      assert_assembles_to "\x66\xA5", :movsw
      assert_assembles_to "\xA5", :movsd
      assert_assembles_to "\x48\xA5", :movsq
    end

    def test_nop
      assert_assembles_to "\x66\x0F\x1F\xC0", :nop_rm16, reg0: :a
      assert_assembles_to "\x0F\x1F\xC0", :nop_rm32, reg0: :a
    end

    def test_movq_mm
      assert_assembles_to "\x48\x0F\x6E\xC0", :movq_mm_rm64, reg0: :mm0, reg1: :a
      assert_assembles_to "\x48\x0F\x6E\x00", :movq_mm_rm64, reg0: :mm0, reg_base: :a
    end

    def test_movd_mm
      assert_assembles_to "\x0F\x6E\xC0", :movd_mm_rm32, reg0: :mm0, reg1: :a
      assert_assembles_to "\x0F\x6E\x00", :movd_mm_rm32, reg0: :mm0, reg_base: :a
    end

    def test_movq_xmm
      assert_assembles_to "\x66\x48\x0F\x6E\xC0", :movq_xmm_rm64, reg0: :xmm0, reg1: :a
      assert_assembles_to "\x66\x49\x0F\x6E\xC4", :movq_xmm_rm64, reg0: :xmm0, reg1: :r12
      assert_assembles_to "\x66\x4D\x0F\x6E\xE4", :movq_xmm_rm64, reg0: :xmm12, reg1: :r12

      assert_assembles_to "\x66\x4D\x0F\x6E\x24\x24", :movq_xmm_rm64, reg0: :xmm12, reg_base: :r12
    end

    def test_movd_xmm
      assert_assembles_to "\x66\x0F\x6E\xC0", :movd_xmm_rm32, reg0: :xmm0, reg1: :a
      assert_assembles_to "\x66\x41\x0F\x6E\xC4", :movd_xmm_rm32, reg0: :xmm0, reg1: :r12
      assert_assembles_to "\x66\x45\x0F\x6E\xE4", :movd_xmm_rm32, reg0: :xmm12, reg1: :r12

      assert_assembles_to "\x66\x45\x0F\x6E\x24\x24", :movd_xmm_rm32, reg0: :xmm12, reg_base: :r12
    end

    def test_xchg_implicit
      assert_assembles_to "\x66\x93", :xchg_ax_r16, reg0: :b
      assert_assembles_to "\x93", :xchg_eax_r32, reg0: :b
      assert_assembles_to "\x48\x93", :xchg_rax_r64, reg0: :b
    end

    SIMD_CMP_INSTRUCTION_NAMES = %i(
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

    NOP_INSTRUCTION_NAMES = %i(
      nop_rm16
      nop_rm32
    ).freeze

    XCHG_IMPLICIT_INSTRUCTION_NAMES = %i(
      xchg_ax_r16
      xchg_eax_r32
      xchg_rax_r64
    ).freeze

    CMPS_INSTRUCTION_NAMES = %i(
      cmpsb
      cmpsw
      cmpsd
      cmpsq
    ).freeze

    LODS_INSTRUCTION_NAMES = %i(
      lodsb
      lodsw
      lodsd
      lodsq
    ).freeze

    MOVS_INSTRUCTION_NAMES = %i(
      movsb
      movsw
      movsd
      movsq
    ).freeze

    MOVQ_MM_INSTRUCTION_NAMES = %i(
      movq_mm_rm64
      movq_rm64_mm
    ).freeze

    MOVD_MM_INSTRUCTION_NAMES = %i(
      movd_mm_rm32
      movd_rm32_mm
    ).freeze

    MOVQ_XMM_INSTRUCTION_NAMES = %i(
      movq_xmm_rm64
      movq_rm64_xmm
    ).freeze

    MOVD_XMM_INSTRUCTION_NAMES = %i(
      movd_xmm_rm32
      movd_rm32_xmm
    ).freeze

    class InstructionTest
      attr_reader :instruction

      class ActualOperand

        REGISTERS = {
          a: {
            8 => 'al',
            16 => 'ax',
            32 => 'eax',
            64 => 'rax'
          },
          b: {
            8 => 'bl',
            16 => 'bx',
            32 => 'ebx',
            64 => 'rbx'
          },
          c: {
            8 => 'cl',
            16 => 'cx',
            32 => 'ecx',
            64 => 'rcx'
          },
          r11: {
            8 => 'r11b',
            16 => 'r11w',
            32 => 'r11d',
            64 => 'r11'
          },
          r12: {
            8 => 'r12b',
            16 => 'r12w',
            32 => 'r12d',
            64 => 'r12'
          },
          xmm0: {
            128 => 'xmm0',
            256 => 'ymm0'
          },
          xmm1: {
            128 => 'xmm1',
            256 => 'ymm1'
          },
          xmm2: {
            128 => 'xmm2',
            256 => 'ymm2'
          },
          xmm3: {
            128 => 'xmm3',
            256 => 'ymm3'
          },
          xmm10: {
            128 => 'xmm10',
            256 => 'ymm10'
          },
          xmm11: {
            128 => 'xmm11',
            256 => 'ymm11'
          },
          mm0: {
            64 => 'mm0'
          },
          mm1: {
            64 => 'mm1'
          },
          mm7: {
            64 => 'mm7'
          }
        }.freeze

        attr_reader :parameter_name
        attr_reader :parameter_value
        attr_reader :type, :size

        def initialize(type, parameter_name, parameter_value, size = nil)
          @type = type
          @parameter_name = parameter_name
          @parameter_value = parameter_value
          @size = size
        end

        def parameter_names
          Array(@parameter_name)
        end

        def parameter_values
          Array(@parameter_value)
        end

        def disassembly(encoded_instruction = nil)
          send :"#{type}_disassembly", encoded_instruction
        end

        private

        def imm_disassembly(encoded_instruction)
          value = parameter_value
          value += encoded_instruction.bytesize if parameter_name == :rel

          if value == 1
            value.to_s
          else
            "0x#{value.to_s(16)}"
          end
        end

        def reg_disassembly(encoded_instruction)
          REGISTERS.fetch(parameter_value).fetch(size)
        end

        def mem_disassembly(encoded_instruction)
          pointer =
            if parameter_name == :moffs
              "0x#{parameter_value.to_s(16)}"
            else
              base_register, = REGISTERS.fetch_values(*parameter_value).map do |sizes|
                if sizes.key? 64
                  sizes[64]
                else
                  sizes[128]
                end
              end

              base_register
            end

          "#{pointer_size} ptr [#{pointer}]"
        end

        def pointer_size
          case size
          when 8
            'byte'
          when 16
            'word'
          when 32
            'dword'
          when 64
            'qword'
          when 128
            'xmmword'
          when 256
            'ymmword'
          when nil
            ''
          else
            raise "invalid pointer size #{size}"
          end
        end

      end

      class ActualOperands
        attr_reader :formal_operand

        REGISTERS = {
          gp: %i(a c b r11 r12),
          xmm: %i(xmm0 xmm1 xmm10 xmm11),
          mm: %i(mm0 mm1 mm7)
        }.freeze

        SKIP_IMPLICIT_XMM0_INSTRUCTION_NAMES = %i(
          blendvpd_xmm_xmmm128_xmm0
          blendvps_xmm_xmmm128_xmm0
          pblendvb_xmm_xmmm128_xmm0
        ).freeze

        IMMEDIATE_VALUES = {
          imm: 0x4a,
          imm0: 0x4a,
          imm1: 0x4b,
          rel: 0x4c,
          moffs: 0x4d,
        }.freeze

        def initialize(formal_operand)
          @formal_operand = formal_operand
          @actual_operands = []

          load
        end

        def parameter_name
          formal_operand.parameter&.name
        end

        def to_a
          @actual_operands
        end

        def empty?
          @actual_operands.empty?
        end

        private

        def load
          if formal_operand.mnemonic?
            p formal_operand.type if formal_operand.instruction.name == :mov_al_moffs8
            case formal_operand.type
            when :reg
              add_register_operand
            when :rm
              add_register_operand
              add_memory_operand
            when :imm
              add_immediate_operand
            when :mem
              add_memory_operand
            else
              raise "unknown operand type #{formal_operand.type}"
            end
          end
        end

        def add_register_operand
          if formal_operand.implicit?
            register = formal_operand.register
            unless register == :xmm0 && skip_implicit_xmm0?
              @actual_operands << ActualOperand.new(:reg, nil,
                                                    formal_operand.register,
                                                    formal_operand.size)
            end
          else
            raise 'missing parameter' unless formal_operand.parameter
            REGISTERS.fetch(formal_operand.register_type).each do |register|
              @actual_operands << ActualOperand.new(:reg, parameter_name,
                                                    register, formal_operand.size)
            end
          end
        end

        def add_memory_operand
          if parameter_name == :moffs
            @actual_operands << ActualOperand.new(:mem,
                                                  parameter_name,
                                                  IMMEDIATE_VALUES.fetch(parameter_name),
                                                  memory_size)
          else
            REGISTERS.fetch(:gp).each do |register|
              @actual_operands << ActualOperand.new(:mem,
                                                    [:reg_base],
                                                    [register],
                                                    memory_size)
            end
          end
        end

        def add_immediate_operand
          @actual_operands <<
            if formal_operand.implicit?
              ActualOperand.new(:imm, parameter_name, formal_operand.immediate)
            else
              p [parameter_name, IMMEDIATE_VALUES.fetch(parameter_name)]
              ActualOperand.new(:imm, parameter_name, IMMEDIATE_VALUES.fetch(parameter_name))
            end
        end

        def skip_implicit_xmm0?
          SKIP_IMPLICIT_XMM0_INSTRUCTION_NAMES.include? formal_operand.instruction.name
        end

        def memory_size
          # Workaround bug in Capstone
          # which reports wrong pointer size
          # (xmmword instead of qword/dword)
          case formal_operand.instruction.name
          when :comisd_xmm_xmmm64
            128
          when :comiss_xmm_xmmm32
            128
          else
            formal_operand.memory_size
          end
        end
      end

      def initialize(test_class, instruction)
        @test_class = test_class
        @instruction = instruction
      end

      def mnemonics
        case instruction.name
        when :clflushopt_m8
          # Capstone, might be a bug
          %w(clflush)
        else
          instruction.mnemonics
        end
      end

      def run(test)
        # Capstone prints rm operand last
        operands = instruction.operands.map do |operand|
          ActualOperands.new operand
        end.reject(&:empty?)
        operands.reverse! if instruction.name =~ /^test_rm\d+_r\d+/

        combinations =
          if operands.empty?
            [[]]
          else
            combinations = operands.first.to_a.product(*(operands[1..-1] || []).map(&:to_a))
          end

        raise if combinations.empty?
        combinations.each do |combination|
          parameters = combination.each_with_object(Evoasm::X64::Parameters.new) do |operand, parameters|
            operand.parameter_names.zip(operand.parameter_values) do |name, value|
              parameters[name] = value
            end
          end

          encoded_instruction = instruction.encode parameters

          operands_disassembly = combination.map do |operand|
            operand.disassembly encoded_instruction
          end

          expected_disassemblys = mnemonics.map do |mnemonic|
            "#{mnemonic.downcase} #{operands_disassembly.join(', ')}"
          end

          test.assert_includes expected_disassemblys, test.disassemble(encoded_instruction)
        end
      end

      def basic?
        @basic
      end

      def define!
        run_method = method(:run)
        @test_class.send :define_method, test_method_name do
          run_method.call self
        end
      end

      private

      def test_method_name
        :"test_#{instruction.name}"
      end
    end

    Evoasm::Libevoasm.enum_type(:x64_inst_id).symbols.each do |instruction_name|
      next if instruction_name == :n_insts
      # Capstone uses pseudo-mnemonics, tested separately
      next if SIMD_CMP_INSTRUCTION_NAMES.include? instruction_name

      # Capstone does not like these for some reason, test separately
      next if NOP_INSTRUCTION_NAMES.include? instruction_name
      next if XCHG_IMPLICIT_INSTRUCTION_NAMES.include? instruction_name

      # Capstone gives implicit operands for these
      next if CMPS_INSTRUCTION_NAMES.include? instruction_name
      next if LODS_INSTRUCTION_NAMES.include? instruction_name
      next if MOVS_INSTRUCTION_NAMES.include? instruction_name

      # Most (dis)assemblers (including Capstone) use the MOVD mnemonic for both
      # movq and movd, and MOVQ (but sometimes also MOVD) for the XMM version.
      # Oddly, GNU AS correctly uses the MM version if movq
      # is used with register operands but does use the XMM version
      # for SIB operands.
      # Anyway, Capstone does not get this 100% right, or at least not
      # how we need it.
      next if MOVQ_MM_INSTRUCTION_NAMES.include? instruction_name
      next if MOVD_MM_INSTRUCTION_NAMES.include? instruction_name
      next if MOVD_XMM_INSTRUCTION_NAMES.include? instruction_name
      next if MOVQ_XMM_INSTRUCTION_NAMES.include? instruction_name

      instruction = Evoasm::X64.instruction instruction_name
      instruction_test = InstructionTest.new self, instruction
      instruction_test.define!
    end
  end
end