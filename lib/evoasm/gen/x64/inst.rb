require 'evoasm/gen/state_dsl'
require 'evoasm/gen/x64/enc'
require 'evoasm/core_ext/array'
require 'evoasm/core_ext/integer'

module Evoasm
  module Gen
    module X64
      Inst = Struct.new :mnem, :opcode,
                        :operands,
                        :encoding, :features,
                        :prefs, :name, :index,
                        :flags, :exceptions do
        COL_OPCODE = 0
        COL_MNEM = 1
        COL_OP_ENC = 2
        COL_OPS = 3
        COL_PREFS = 4
        COL_FEATURES = 5
        COL_EXCEPTIONS = 6

        HEX_BYTE_REGEXP = /^[A-F0-9]{2}$/

        IMM_OP_REGEXP = /^(imm|rel)(\d+)?$/
        MEM_OP_REGEXP = /^m(\d*)$/
        MOFFS_OP_REGEXP = /^moffs(\d+)$/
        VSIB_OP_REGEXP = /^vm(\d+)(?:x|y)$/
        RM_OP_REGEXP = %r{^(r\d*|xmm|ymm|zmm|mm)?/m(\d+)$}
        REG_OP_REGEXP = /^(r|xmm|ymm|zmm|mm)(8|16|32|64)?$/

        Operand = Struct.new :name, :param, :type, :size, :access,
                             :encoded, :mnem, :reg, :implicit,
                             :reg_type, :accessed_bits do
          alias_method :encoded?, :encoded
          alias_method :mnem?, :mnem
          alias_method :implicit?, :implicit
        end

        include Evoasm::Gen::StateDSL

        private def xmm_regs(zmm: false)
          regs = X64::REGISTERS.fetch(:xmm).dup
          regs.concat X64::REGISTERS.fetch(:zmm) if zmm

          regs
        end

        # NOTE: enum domains need to be sorted
        # (i.e. by their corresponding C enum numberic value)
        GP_REGISTERS = X64::REGISTERS.fetch(:gp)[0..-5] - [:SP]
        def param_domain(param_name)
          domain =
            case param_name
            when :rex_b, :rex_r, :rex_x, :rex_w,
                 :vex_l, :force_rex?, :lock?, :force_sib?,
                 :force_disp32?, :force_long_vex?
              (0..1)
            when :address_size
              [16, 32, 64]
            when :disp_size
              [16, 32]
            when :scale
              [1, 2, 4, 8]
            when :modrm_reg
              (0..7)
            when :vex_v
              (0..15)
            when :reg_base
              GP_REGISTERS
            when :reg_index
              case reg_operands[1].type
              when :vsib
                X64::REGISTERS.fetch :xmm
              when :mem, :rm
                GP_REGISTERS
              else
                fail
              end
            when :imm0, :imm1, :imm, :moffs, :rel
              imm_op = encoded_operands.find {|op| op.param == param_name}
              case imm_op.size
              when 8
                (:INT8_MIN..:INT8_MAX)
              when 16
                (:INT16_MIN..:INT16_MAX)
              when 32
                (:INT32_MIN..:INT32_MAX)
              when 64
                (:INT64_MIN..:INT64_MAX)
              else
                fail "unexpected imm size '#{imm_size}' (#{imm_ops})"
              end
            when :disp
              (:INT32_MIN..:INT32_MAX)
            when :reg0, :reg1, :reg2, :reg3
              reg_op = encoded_operands.find { |op| op.param == param_name }

              case reg_op.reg_type
              when :xmm
                xmm_regs zmm: false
              when :zmm
                xmm_regs zmm: true
              when :gp
                GP_REGISTERS
              else
                X64::REGISTERS.fetch reg_op.reg_type
              end
            else
              fail "missing domain for param #{param_name}"
            end

          domain
        end

        def self.load(rows)
          insts = rows.map.with_index do |row, index|
            X64::Inst.new(index, row)
          end

          # make sure name is unique
          insts.group_by(&:name).each do |name, group|
            if group.size > 1
              group.each_with_index do |inst, index|
                inst.name << "_#{index}"
              end
            end
          end

          insts
        end

        def initialize(index, row)
          self.index = index
          self.mnem = row[COL_MNEM]
          self.encoding = row[COL_OP_ENC]
          self.opcode = row[COL_OPCODE].split(/\s+/)

          load_features row
          load_exceptions row
          load_operands row
          load_prefs row

          load_flags

          self.name = inst_name
        end

        def inst_name
          ops_str = operands.select(&:mnem?).map do |op|
            op.name.gsub('/m', 'm').downcase
          end.join('_')

          name = mnem.downcase.tr('/', '_')
          name << "_#{ops_str}" unless ops_str.empty?
          name
        end

        private def load_features(row)
          self.features = row[COL_FEATURES].strip
                          .tr('/', '_')
                          .split('+')
                          .delete_if(&:empty?)
                          .map { |f| "#{f.downcase}".to_sym }
                          .uniq
        end

        private def load_exceptions(row)
          exceptions = row[COL_EXCEPTIONS]

          self.exceptions =
            if exceptions.nil?
              []
            else
              exceptions.strip
                        .split('; ')
                        .map { |f| "#{f.downcase}".to_sym }
            end
        end

        private def load_prefs(row)
          self.prefs =
            row[COL_PREFS].split('; ').map do |op|
              op =~ %r{(.+?):(.+?)/(.+)} or fail("invalid prefix op '#{op}'")
              value =
                begin
                  Integer($3)
                rescue
                  $3.to_sym
                end

              [$1.to_sym, [$2.to_sym, value]]
            end.to_h
        end

        def self.max_reg_params
          4
        end

        def reg_param_operands
          operands.select do |op|
            (op.type == :reg || op.type == :rm) && op.param
          end
        end


        private def accessable(type, reg_types = [])
         operands.each_with_object({}) do |op, hash|
            params_or_regs = Array(op.send(type))

            next unless (op.type == :reg || op.type == :rm) &&
              !params_or_regs.empty?

            next unless reg_types.include? op.reg_type

            params_or_regs.each do |param_or_reg|
              hash[param_or_reg] = op.access
            end
          end
        end

        IGNORED_OPERAND_NAMES = X64::IGNORED_RFLAGS + X64::IGNORED_MXCSR
        def load_operands(row)
          ops = row[COL_OPS].split('; ').map do |op|
            op =~ /(.*?):([a-z]+(?:\[\d+\.\.\d+\])?)/ || fail
            [$1, $2]
          end

          imm_counter = 0
          reg_counter = 0

          self.operands = []

          ops.each do |op_name, flags|
            next if IGNORED_OPERAND_NAMES.include? op_name.to_sym

            if op_name.upcase == op_name
              add_implicit_operand op_name, flags
            else
              reg_counter, imm_counter = add_operand op_name, flags, reg_counter, imm_counter
            end
          end
        end

        private def build_operand(op_name, flags)
          Operand.new.tap do |operand|
            operand.name = op_name
            operand.access = flags.gsub(/[^crwu]/, '').each_char.map(&:to_sym)
            operand.accessed_bits = {}
            flags.scan(/([crwu])\[(\d+)\.\.(\d+)\]/) do |acc, from, to|
              operand.accessed_bits[acc.to_sym] = (from.to_i..to.to_i)
            end
            operand.encoded = flags.include? 'e'
            # mnem operand
            operand.mnem = flags.include? 'm'
          end
        end

        private def add_operand(op_name, flags, reg_counter, imm_counter)
          operand = build_operand op_name, flags

          case op_name
          when IMM_OP_REGEXP
            operand.type = :imm
            operand.size = $2 && $2.to_i

            if $1 == 'imm'
              operand.param = :"imm#{imm_counter}"
              imm_counter += 1
            else
              operand.param = $1.to_sym
            end
          when RM_OP_REGEXP
            operand.type = :rm
            operand.reg_type, operand.size = reg_type_and_size($1, $2)
          when REG_OP_REGEXP
            operand.type = :reg
            operand.reg_type, operand.size = reg_type_and_size($1, $2)
          when MEM_OP_REGEXP
            operand.type = :mem
            operand.size = $1.empty? ? nil : $1.to_i
          when MOFFS_OP_REGEXP
            operand.type = :mem
            operand.size = Integer($1)
            operand.param = :moffs
          when VSIB_OP_REGEXP
            operand.type = :vsib
            operand.size = $1.to_i
          else
            raise "unexpected operand '#{op_name}'"
          end

          if (operand.type == :rm || operand.type == :reg)
            operand.param = :"reg#{reg_counter}"
            reg_counter += 1
          end

          self.operands << operand

          [reg_counter, imm_counter]
        end

        ALLOWED_REG_SIZES = [8, 16, 32, 64]
        private def reg_type_and_size(type_match, size_match)
          case type_match
          when 'r'
            size = Integer(size_match)
            raise "invalid reg size #{size}" unless ALLOWED_REG_SIZES.include?(size)
            [:gp, size]
          when 'r32'
            [:gp, 32]
          when 'xmm'
            [:xmm, 128]
          when 'ymm'
            [:xmm, 256]
          when 'zmm'
            [:zmm, 512]
          when 'mm'
            [:mm, 64]
          else
            fail "unexpected reg type '#{type_match}/#{size_match}'"
          end
        end

        private def reg_size(reg_type, match)
          case reg_type
          when :xmm
            128
          when 'xmm', 'ymm'
            :xmm
          when 'zmm'
            :zmm
          when 'mm'
            :mm
          else
            fail "unexpected reg type '#{reg_op.match}' (#{reg_op})"
          end
        end

        def load_flags
          flags = []
          operands.each do |op|
            flags << op.reg_type
            flags << :sp if op.reg == :SP
            flags << :mem if op.type == :mem
          end
          flags.uniq!
          flags.compact!

          self.flags = flags
        end

        RFLAGS = X64::REGISTERS.fetch :rflags
        MXCSR = X64::REGISTERS.fetch :mxcsr

        private def add_implicit_operand(op_name, flags)
          if op_name == 'FLAGS' || op_name == 'RFLAGS'
            # NOTE: currently all used flags
            # fall within the bits of 32-bit FLAGS
            # i.e. all upper bits of RFLAGS are unused
            RFLAGS.each do |reg_name|
              add_implicit_operand(reg_name.to_s, flags)
            end
            return
          end

          if op_name =~ /^\d$/
            operand = build_operand op_name, flags
            operand.type = :imm
          else
            reg_name = op_name.gsub(/\[|\]/, '')
            operand = build_operand reg_name, flags
            operand.type = op_name =~ /^\[/ ? :mem : :reg

            #FIXME: find a way to handle
            # this: memory expressions involving
            # multiple registers e.g. [RBX + AL] in XLAT
            if reg_name =~ /\+/
              reg_name = reg_name.split(/\s*\+\s*/).first
            end

            sym_reg = reg_name.to_sym

            if RFLAGS.include?(sym_reg)
              operand.reg = sym_reg
              operand.reg_type = :rflags
            elsif MXCSR.include?(sym_reg)
              operand.reg = sym_reg
              operand.reg_type = :mxcsr
            else
              operand.reg =
                case reg_name
                when 'RAX', 'EAX', 'AX', 'AL'
                  :A
                when 'RCX', 'ECX', 'CX', 'CL'
                  :C
                when 'RDX', 'EDX', 'DX'
                  :D
                when 'RBX', 'EBX'
                  :B
                when 'RSP', 'SP'
                  :SP
                when 'RBP', 'BP'
                  :BP
                when 'RSI', 'ESI', 'SIL', 'SI'
                  :SI
                when 'RDI', 'EDI', 'DIL', 'DI'
                  :DI
                when 'RIP'
                  operand.reg_type = :ip
                  :IP
                when 'XMM0'
                  operand.reg_type = :xmm
                  :XMM0
                else
                  fail ArgumentError, "unexpected register '#{reg_name}'"
                end
              operand.reg_type = :gp
            end
          end

          operand.implicit = true

          self.operands << operand
        end

        def vex?
          opcode[0] =~ /^VEX/
        end

        MAND_PREF_BYTES = %w(66 F2 F3 F0)
        def write_byte_str(byte_str)
          write Integer(byte_str, 16), 8
        end

        def mand_pref_byte?(byte)
          MAND_PREF_BYTES.include? byte
        end

        def encode_mand_pref
          write_byte_str opcode.shift while mand_pref_byte? opcode.first
        end

        def opcode_shift(first = nil)
          opcode.shift if first.nil? || opcode.first == first
        end

        LEGACY_PREF_BYTES = {
          cs_bt: 0x2E,
          ss: 0x36,
          ds_bnt: 0x3E,
          es: 0x26,
          fs: 0x64,
          gs: 0x65,
          lock: 0xF0,
          pref66: 0x66,
          pref67: 0x67
        }

        LEGACY_PREF_CONDS = {
          pref67: [:eq, :address_size, 32]
        }

        def encode_legacy_prefs(&block)
          writes = []

          LEGACY_PREF_BYTES.each do |pref, byte|
            next unless prefs.key? pref
            needed, = prefs.fetch pref

            cond =
              case needed
              when :required
                true
              when :optional
                :"#{pref}?"
              when :operand
                LEGACY_PREF_CONDS.fetch pref
              else
                fail
              end

            writes << [cond, [byte, 8]]
          end

          return block[] if writes.empty?

          unordered_writes :legacy_pref_order, writes
          to(&block)
        end

        def encode_opcode
          write_byte_str opcode.shift while opcode.first =~ HEX_BYTE_REGEXP
        end

        def encode_o_opcode
          return unless encoding.include? 'O'
          opcode.shift =~ /^([[:xdigit:]]{2})\+r(?:b|w|d|q)$/ || fail
          byte = Integer($1, 16)
          write [:add, byte, [:mod, [:reg_code, :reg0], 8]], 8
          reg_op, = reg_operands
          reg_op.param == :reg0 or fail "expected reg_op to have param reg0 not #{reg_op.param}"
          access :reg0, reg_op.access
        end

        def encodes_modrm?
          encoding.include? 'M'
        end

        def encode_modrm_sib(&block)
          return block[] unless encodes_modrm?

          # modrm_reg is the bitstring
          # that is used directly to set the ModRM.reg bits
          # and can be an opcode extension
          # reg_reg is a *register*.
          # if given instead, it is properly handled and encoded
          reg_op, rm_op, = reg_operands

          byte = opcode.shift
          byte =~ %r{/(r|\d|\?)} or fail "unexpected opcode byte #{byte} in #{mnem}"

          reg_reg_param, rm_reg_param, modrm_reg =
            case $1
            when 'r'
              [reg_op.param, rm_op.param, nil]
            when /^(\d)$/
              [nil, rm_op.param, Integer($1)]
            when '?'
              [nil, rm_op.param, nil]
            else
              fail "unexpected modrm reg specifier '#{$1}'"
            end

          rm_reg_access = rm_op&.access
          reg_reg_access = reg_op&.access

          rm_type = rm_op.type

          modrm_sib = ModRMSIB.new reg_reg_param: reg_reg_param,
                                   rm_reg_param: rm_reg_param,
                                   rm_type: rm_type,
                                   modrm_reg: modrm_reg,
                                   rm_reg_access: rm_reg_access,
                                   reg_reg_access: reg_reg_access

          call modrm_sib

          to(&block)
        end

        def rex_possible?
          encoding =~ /M|O|R/
        end

        def encode_rex_or_vex(&block)
          if vex?
            encode_vex(&block)
          elsif rex_possible?
            encode_rex(&block)
          else
            block[]
          end
        end

        def encode_vex(&block)
          vex = opcode.shift.split '.'
          fail "invalid VEX start '#{vex.first}'" unless vex.first == 'VEX'

          vex_m =
            if vex.include? '0F38'
              0b10
            elsif vex.include? '0F3A'
              0b11
            else
              0b01
            end

          vex_p =
            if vex.include? '66'
              0b01
            elsif vex.include? 'F3'
              0b10
            elsif vex.include? 'F2'
              0b11
            else
              0b00
            end

          # vex_type = vex.&(%w(NDS NDD DDS)).first

          rex_w =
            if vex.include? 'W1'
              0b01
            elsif vex.include? 'W0'
              0b00
            end

          reg_op, rm_op, vex_op = reg_operands

          if vex_op
            access vex_op.param, vex_op.access
          end

          vex_v =
            case encoding
            when 'RVM', 'RVMI', 'RVMR', 'MVR', 'RMV', 'RMVI', 'VM', 'VMI'
              [:reg_code, vex_op.param]
            when 'RM', 'RMI', 'XM', 'MR', 'MRI', 'M'
              0b0000
            when 'NP'
              nil
            else
              fail "unknown VEX encoding #{encoding} in #{mnem}"
            end

          vex_l =
            if vex.include? 'LIG'
              nil
            else
              if vex.include? '128'
                0b0
              elsif vex.include? '256'
                0b1
              elsif vex.include? 'LZ'
                0b0
                # [:if, [:eq, [:operand_size], 128], 0b0, 0b1]
              end
            end

          vex = VEX.new rex_w: rex_w,
                        reg_reg_param: reg_op&.param,
                        rm_reg_param: rm_op&.param,
                        vex_m: vex_m,
                        vex_v: vex_v,
                        vex_l: vex_l,
                        vex_p: vex_p

          call vex
          to(&block)
        end

        private def encoded_operands
          @encoded_operands ||= operands.select(&:encoded?)
        end

        def encoded_operand_names
          encoded_operands.map(&:name)
        end

        private def reg_operands
          return @regs if @regs

          r_idx = encoding.index(/R|O/)
          reg_reg = r_idx && encoded_operands[r_idx]

          m_idx = encoding.index 'M'
          reg_rm = m_idx && encoded_operands[m_idx]

          v_idx = encoding.index 'V'
          reg_vex = v_idx && encoded_operands[v_idx]

          @regs = [reg_reg, reg_rm, reg_vex]
        end

        def encode_rex(&block)
          rex_w_required, rex_w_value = prefs[:rex_w]

          case rex_w_required
          # 64-bit operand size
          when :required
            force_rex = true
            rex_w = rex_w_value
          # non 64-bit operand size
          # only to access extended regs
          when :optional
            force_rex = false

            rex_w = case rex_w_value
                    when :any then nil
                    when 0x0 then 0x0
                    else fail "unexpected REX pref value #{rex_w_value}"
                    end
          else
            force_rex = false
            rex_w = nil
          end

          reg_op, rm_op, _ = reg_operands

          rex = REX.new force: force_rex,
                        rex_w: rex_w,
                        reg_reg_param: reg_op&.param,
                        rm_reg_param: rm_op&.param,
                        rm_reg_type: rm_op&.type,
                        modrm: encodes_modrm?

          call rex
          to(&block)
        end

        def imm_param_name
          case encoding
          when 'FD', 'TD'
            :moffs
          when 'D'
            :rel
          else
            @imm_counter ||= 0
            :"imm#{@imm_counter}".tap do
              @imm_counter += 1
            end
          end
        end

        def encode_imm_or_imm_reg
          while byte = opcode.shift
            case byte
            when /^(?:i|c)(?:b|w|d|o|q)$/
              write imm_param_name, imm_code_size(byte)
            when '/is4'
              write [:shl, [:reg_code, :reg3], 4], 8
            else
              fail "invalid immediate specifier '#{byte}'"\
                  " found in immediate encoding #{mnem}" if encoding =~ /I$/
            end
          end
        end

        def access_implicit_ops
          operands.each do |op|
            if op.implicit? && op.type == :reg
              access op.reg, op.access
            end
          end
        end

        state def root_state
          state do
            comment mnem
            log :debug, name

            access_implicit_ops

            encode_legacy_prefs do
              encode_mand_pref
              encode_rex_or_vex do
                encode_opcode
                encode_o_opcode

                encode_modrm_sib do
                  encode_imm_or_imm_reg
                  done
                end
              end
            end
          end
        end

        def imm_code_size(code)
          case code
          when 'ib', 'cb' then 8
          when 'iw', 'cw' then 16
          when 'id', 'cd' then 32
          when 'io', 'cq' then 64
          else fail "invalid imm code #{code}"
          end
        end

        def done
          ret
        end

      end

      class Inst
        OPERAND_TYPES = %i(reg rm vsib mem imm)
      end

    end
  end
end
