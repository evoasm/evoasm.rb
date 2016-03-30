require 'awasm/gen/state_dsl'
require 'awasm/core_ext/kwstruct'

module Awasm::Gen
  module X64
    VEX = KwStruct.new :rex_w, :reg_reg_param, :rm_reg_param, :vex_m, :vex_v, :vex_l, :vex_p do
      include StateDSL

      state def two_byte_vex
        state do
          log :trace, 'writing vex'
          write 0b11000101, 8
          write [
            [:neg, :rex_r],
            [:neg, vex_v || :vex_v],
            (vex_l || :vex_l),
            vex_p
          ], [1, 4, 1, 2]
          ret
        end
      end

      state def three_byte_vex
        state do
          log :trace, 'writing vex'
          write 0b11000100, 8
          write [[:neg, :rex_r],
                 [:neg, :rex_x],
                 [:neg, :rex_b],
                 vex_m], [1, 1, 1, 5]
          write [rex_w || :rex_w,
                 [:neg, vex_v || :vex_v],
                 vex_l || :vex_l,
                 vex_p], [1, 4, 1, 2]
          ret
        end
      end

      def zero_rex?
        cond =
          [:and,
           [:eq, :rex_x, 0b0],
           [:eq, :rex_b, 0b0]
          ]

        cond << [:eq, :rex_w, 0b0] unless rex_w == 0x0

        cond
      end

      state def root_state
        state do
          comment 'VEX'

          # assume rex_w and vex_l set
          # default unset 0 is ok for both
          if vex_m == 0x01 && rex_w != 0x1
            to_if :and, zero_rex?, [:false?, :force_long_vex?], two_byte_vex
            else_to three_byte_vex
          else
            to three_byte_vex
          end
        end
      end
    end

    REX = KwStruct.new :rex_w, :reg_reg_param, :rm_reg_param, :force, :rm_reg_type, :modrm do
      include StateDSL

      alias_method :modrm?, :modrm
      # reg_reg_param
      # and rm_reg_param
      # are REGISTERS
      # and NOT register ids
      # or bitfield values

      def rex_bit(reg)
        [:div, [:reg_code, reg], 8]
      end

      def base_or_index?
        modrm? && rm_reg_type != :reg
      end

      def need_rex?
        cond = [:or]
        cond << [:neq, rex_bit(reg_reg_param), 0] if reg_reg_param
        cond << [:and, [:set?, rm_reg_param], [:neq, rex_bit(rm_reg_param), 0]] if rm_reg_param

        cond << [:and, [:set?, :reg_base],  [:neq, rex_bit(:reg_base), 0]] if  base_or_index?
        cond << [:and, [:set?, :reg_index], [:neq, rex_bit(:reg_index), 0]] if base_or_index?

        cond == [:or] ? false : cond
      end

      state def rex_b
        state do
          log :trace, 'setting rex_b... modrm_rm='

          #FIXME: can REX.b ever be ignored ?
          #set :_rex_b, :rex_b
          #to write_rex

          rex_b_rm_reg = proc do
            set :_rex_b, rex_bit(rm_reg_param)
            to write_rex
          end

          rex_b_reg_reg = proc do
            set :_rex_b, rex_bit(reg_reg_param)
            to write_rex
          end

          rex_b_base_reg = proc do
            log :trace, 'setting rex_b from base'
            set :_rex_b, rex_bit(:reg_base)
            to write_rex
          end

          if !modrm?
            if reg_reg_param
              rex_b_reg_reg[]
            else
              fail
            end
          else
            case rm_reg_type
            when :reg
              log :trace, 'setting rex_b from modrm_rm'
              rex_b_rm_reg[]
            when :rm
              to_if :set?, :reg_base, &rex_b_base_reg
              else_to(&rex_b_rm_reg)
            when :mem
              rex_b_base_reg[]
            else
              fail
            end
          end
        end
      end

      state def rex_rx
        state do
          # MI and other encodings
          # do not use the MODRM.reg field
          # so the corresponding REX bit
          # is ignored

          set_rex_r_free = proc do
            set :_rex_r, :rex_r
          end

          rex_x_free = proc do
            set :_rex_x, :rex_x
            to rex_b
          end

          rex_x_index = proc do
            set :_rex_x, rex_bit(:reg_index)
            log :trace, 'rex_b... A'
            to rex_b
          end

          if modrm?
            if reg_reg_param
              set :_rex_r, rex_bit(reg_reg_param)
            else
              set_rex_r_free[]
            end

            case rm_reg_type
            when :reg
              rex_x_free[]
            when :rm
              to_if :set?, :reg_index, &rex_x_index
              else_to(&rex_x_free)
            when :mem
              rex_x_index[]
            else
              fail
            end
          else
            set_rex_r_free[]
            rex_x_free[]
          end
        end
      end

      state def root_state
        if force
          rex_rx
        else
          # rex?: output REX even if not force
          # need_rex?: REX is required (use of ext. reg.)
          state do
            to_if :or, [:true?, :force_rex?], need_rex?, rex_rx
            else_to do
              ret
            end
          end
        end
      end

      state def write_rex
        state do
          comment 'REX prefix'
          rex_w = self.rex_w

          # assume rex_w is set if the
          # attr rex_w is nil
          # unset default 0 is ok
          rex_w ||= :rex_w

          write [0b0100, rex_w, :_rex_r, :_rex_x, :_rex_b], [4, 1, 1, 1, 1]
          log :trace, 'writing rex % % % %', :rex_w, :_rex_r, :_rex_x, :_rex_b

          ret
        end
      end
    end

    ModRMSIB = KwStruct.new :reg_reg_param, :rm_reg_param, :rm_type, :modrm_reg, :rm_reg_access,
                            :reg_reg_access do
      include StateDSL

      def reg_bits(reg, is_reg_code: false)
        reg_code = if is_reg_code
                   reg
                 else
                   [:reg_code, reg]
                 end
        [:mod, reg_code, 8]
      end

      def write_modrm(mod, rm)
        reg = if modrm_reg
                modrm_reg
              elsif reg_reg_param
                # register, use register parameter specified
                # in reg_reg_param
                reg_bits(reg_reg_param)
              else
                # ModRM.reg is free, use a parameter
                reg_bits(:modrm_reg, is_reg_code: true)
              end

        write [mod, reg, rm], [2, 3, 3]
      end

      def write_sib(scale = nil, index = nil, base = nil)
        write [
          scale || [:log2, :scale],
          index || reg_bits(:_reg_index),
          base || reg_bits(:reg_base)
        ], [2, 3, 3]
      end

      def zero_disp?
        # NOTE: unset disp defaults to 0 as well
        [:eq, :disp, 0]
      end

      def matching_disp_size?
        [:or, [:unset?, :disp_size], [:eq, :disp_size, [:disp_size]]]
      end

      def disp_fits?(size)
        [:ltq, [:disp_size], size]
      end

      def disp?(size)
        [:and,
         disp_fits?(size),
         matching_disp_size?
        ]
      end

      def vsib?
        rm_type == :vsib
      end

      def direct_only?
        rm_type == :reg
      end

      def indirect_only?
        rm_type == :mem
      end

      def modrm_sib_disp(rm:, sib:)
        to_if :and, zero_disp?,
              matching_disp_size?,
              [reg_code_not_in?(:reg_base, 5, 13)] do
          write_modrm 0b00, rm
          write_sib if sib
          ret
        end
        else_to do
          to_if :and, disp_fits?(8), [:false?, :force_disp32?] do
            write_modrm 0b01, rm
            write_sib if sib
            write :disp, 8
            ret
          end
          else_to do
            write_modrm 0b10, rm
            write_sib if sib
            write :disp, 32
            ret
          end
        end
      end

      state def _scale_index_base
        state do
          modrm_sib_disp rm: 0b100, sib: true
        end
      end

      def index_encodable?
        [:neq, [:reg_code, :reg_index], 0b0100]
      end

      state def scale_index_base
        state do
          log :trace, 'scale, index, base'
          set :_reg_index, :reg_index

          if vsib?
            to _scale_index_base
          else
            to_if index_encodable?, _scale_index_base
            else_to do
              # not encodable
              error :not_encodable, "index not encodable", param: :reg_index
            end
          end
        end
      end

      state def disp_only
        state do
          log :trace, 'disp only'
          write_modrm 0b00, 0b100
          write_sib nil, nil, 0b101
          write :disp, 32
          ret
        end
      end

      state def index_only
        state do
          log :trace, 'index only'

          if vsib?
            cond = true
          else
            cond = index_encodable?
          end

          to_if cond do
            set :_reg_index, :reg_index
            write_modrm 0b00, 0b100
            write_sib nil, nil, 0b101
            write :disp, 32
            ret
          end
          if cond != true
            else_to do
              error :not_encodable, "index not encodable (0b0100)", param: :reg_index
            end
          end
        end
      end

      state def base_only_w_sib
        state do
          # need index to encode as 0b100 (RSP, ESP, SP)
          set :_reg_index, :SP
          to _scale_index_base
        end
      end

      def ip_base?
        [:eq, :reg_base, :IP]
      end

      def reg_code_not_in?(reg, *ids)
        [:not_in?, [:reg_code, reg], *ids]
      end

      state def base_only_wo_sib
        state do
          modrm_sib_disp rm: reg_bits(:reg_base), sib: false
        end
      end

      state def base_only
        state do
          log :trace, 'base only'
          to_if ip_base? do
            write_modrm 0b00, 0b101
            write :disp, 32
            ret
          end
          else_to do
            to_if :and, [:false?, :force_sib?], reg_code_not_in?(:reg_base, 4, 12), base_only_wo_sib
            else_to base_only_w_sib
          end
        end
      end

      def no_index?
        [:unset?, :reg_index]
      end

      def no_base?
        [:unset?, :reg_base]
      end

      state def indirect
        state do
          log :trace, 'indirect addressing'
          # VSIB does not allow to omit index
          if vsib?
            to_if no_base? do
              to_if :set?, :reg_index, index_only
              else_to do
                error :missing_param, param: :reg_index
              end
            end
            else_to scale_index_base
          else
            to_if no_base? do
              to_if no_index? do
                to_if :set?, :disp, disp_only
                else_to do
                  error :missing_param, param: :disp
                end
              end
              else_to index_only
            end
            else_to do
              to_if no_index?, base_only
              else_to scale_index_base
            end
          end
        end
      end

      def direct
        state do
          access rm_reg_param, rm_reg_access if rm_reg_param

          write_modrm 0b11, reg_bits(rm_reg_param)
          ret
        end
      end

      def indirect?
        [:or,
         [:set?, :reg_base],
         [:set?, :reg_index],
         [:set?, :disp]
        ]
      end

      state def root_state
        state do
          comment 'ModRM'
          log :trace, 'ModRM'

          access reg_reg_param, reg_reg_access if reg_reg_param

          if direct_only?
            to direct
          else
            to_if indirect?, indirect

            # VSIB does not allow this
            if vsib? || indirect_only?
              else_to do
                error :not_encodable, (vsib? ? "VSIB does not allow indirect addressing" : "indirect addressing not allowed")
              end
            else
              else_to direct
            end
          end
        end
      end
    end
  end
end
