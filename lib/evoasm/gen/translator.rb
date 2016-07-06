require 'erubis'
require 'evoasm/gen/strio'
require 'evoasm/gen/enum'
require 'evoasm/gen/name_util'
require 'evoasm/gen/x64'

module Evoasm
  module Gen
    class BaseTranslator
      include NameUtil

      PARAMS_ARG_HELPERS = %i(address_size operand_size disp_size)
      NO_ARCH_HELPERS = %i(log2)

      def acc_c_type
        name_to_c :bitmap128
      end

      def arch_c_type
        name_to_c arch
      end

      def param_val_c_type
        name_to_c 'arch_param_val'
      end

      def bitmap_c_type
        name_to_c 'bitmap'
      end

      def local_param?(name)
        name.to_s[0] == '_'
      end

      def arch_var_name(indep_arch = false)
        "#{indep_arch ? '((evoasm_arch *)' : ''}#{arch}#{indep_arch ? ')' : ''}"
      end

      def call_to_c(func, args, prefix = nil, eol: false)
        func_name = func.to_s.gsub('?', '_p')

        if prefix
          args.unshift arch_var_name(Array(prefix).first != arch)
        end

        "#{name_to_c func_name, prefix}(#{args.join ','})" + (eol ? ';' : '')
      end

      def params_c_args
        "#{param_val_c_type} *param_vals, "\
          "#{bitmap_c_type} *set_params"
      end


      def params_args
        %w(param_vals set_params)
      end

      def param_to_c(name)
        register_param name.to_sym
        param_name_to_c name
      end

      def register_param(name)
        return if local_param? name
        main_translator.register_param name
        registered_params << name
      end

      def helper_to_c(expr)
        if expr.first.is_a?(Array)
          fail expr.inspect unless expr.size == 1
          expr = expr.first
        end

        name, *args = simplify_helper expr
        case name
        when :eq, :gt, :lt, :gtq, :ltq
          "(#{expr_to_c args[0]} #{cmp_helper_to_c name} #{expr_to_c args[1]})"
        when :if
          "(#{expr_to_c args[0]} ? (#{expr_to_c args[1]}) : #{expr_to_c args[2]})"
        when :neg
          "~(#{expr_to_c args[0]})"
        when :shl
          infix_op_to_c '<<', args
        when :mod
          infix_op_to_c '%', args
        when :div
          infix_op_to_c '/', args
        when :add
          infix_op_to_c '+', args
        when :sub
          infix_op_to_c '-', args
        when :set?
          set_p_to_c(*args)
        when :not
          "!(#{expr_to_c args[0]})"
        when :max, :min
          "#{name.to_s.upcase}(#{args.map { |a| expr_to_c a }.join(', ')})"
        when :and
          infix_op_to_c '&&', args
        when :or
          infix_op_to_c '||', args
        when :in?
          args[1..-1].map { |a| "#{expr_to_c args[0]} == #{expr_to_c a}" }
            .join(" ||\n#{io.indent_str + '   '}")
        else
          if !name.is_a?(Symbol)
            fail unless args.empty?
            expr_to_c name
          else
            call_args = args.map { |a| expr_to_c(a) }
            call_args.concat params_args if PARAMS_ARG_HELPERS.include? name
            if name == :reg_code
              call_args[0] = "(evoasm_#{arch}_reg_id) #{call_args[0]}" 
            end
            helper_call_to_c name, call_args
          end
        end
      end

      def expr_to_c(expr, const_prefix: nil)
        case expr
        when Array
          helper_to_c expr
        when TrueClass
          'true'
        when FalseClass
          'false'
        when Numeric
          expr
        when Symbol, String
          s = expr.to_s
          if s != s.upcase
            get_to_c s
          else
            if X64::REGISTER_NAMES.include?(s.to_sym)
              const_prefix = [arch, 'reg']
            elsif s =~ /^INT\d+_(MAX|MIN)$/
              const_prefix = nil
            end

            name_to_c s, const_prefix, const: true
          end
        else
          fail "invalid expression #{expr.inspect}"
        end
      end

      def func_prototype_to_c(name, func_params = [], static: true)
        func_name = name_to_c name, arch

        func_params_c =
          if func_params.empty?
            ''
          else
            func_params.map do |param_name, type|
              "#{type} #{param_name}"
            end.join(', ').prepend ', '
          end
        "#{static ? 'static ' : ''}evoasm_success\n#{func_name}(#{arch_c_type} *#{arch_var_name},"\
        " #{params_c_args}#{func_params_c})"
      end
    end

    class FuncTranslator < BaseTranslator
      INST_STATE_ID_MIN = 32
      INST_STATE_ID_MAX = 2000

      attr_reader :inst, :registered_params, :root_state
      attr_reader :main_translator, :id_map
      attr_reader :arch, :io, :param_domains

      def initialize(arch, main_translator)
        @arch = arch
        @main_translator = main_translator
        @id = INST_STATE_ID_MAX
        @id_map = Hash.new { |h, k| h[k] = (@id += 1) }
        @registered_params = Set.new
        @param_domains = {}
      end

      def with_io(io)
        @io = io
        yield
        @io = nil
      end

      def pref_func_name(id)
        "prefs_#{id}"
      end

      def inst_id_c_type
        name_to_c :inst_id
      end

      def called_func_name(func, id)
        attrs = func.each_pair.map { |k, v| [k, v].join('_') }.flatten.join('__')
        "#{func.class.name.split('::').last.downcase}_#{attrs}_#{id}"
      end

      def emit_func(name, root_state, func_params = [], local_acc: true, static: true)
        io.puts func_prototype_to_c(name, func_params, static: static), eol: ' {'

        io.indent do
          emit_func_prolog root_state, local_acc
          emit_state root_state
          emit_func_epilog local_acc
        end


        io.puts '}'
        io.puts
      end

      def emit_acc_ary_copy(back_copy = false)
        var_name = 'acc'
        src = "#{arch_var_name arch_indep: true}->#{var_name}"
        dst = var_name

        dst, src = src, dst if back_copy
        io.puts "#{dst} = #{src};"
      end

      def emit_func_prolog(root_state, acc)
        local_params = root_state.local_params
        unless local_params.empty?
          io.puts "#{param_val_c_type} #{local_params.join ', '};"
          local_params.each do |param|
            io.puts "(void) #{param};"
          end
        end

        io.puts 'bool retval = true;'

        if acc
          io.puts "#{acc_c_type} acc;"
          emit_acc_ary_copy
        end
      end

      def error_data_field_to_c(field_name)
        "#{arch_var_name arch_indep: true}->error_data.#{field_name}"
      end

      def emit_error(state, code, msg, reg = nil, param = nil)
        reg_c_val =
          if reg
            reg_name_to_c reg
          else
            "(uint8_t) -1"
          end
        param_c_val =
          if param
            param_to_c param
          else
            "(uint8_t) -1"
          end

        io.write <<-EOL
        evoasm_arch_error_data error_data = {
          .reg = #{reg_c_val},
          .param = #{param_c_val},
          .arch = #{arch_var_name arch_indep: true},
        };
        EOL

        io.puts %Q{evoasm_set_error(EVOASM_ERROR_TYPE_ARCH, #{error_code_to_c code}, &error_data, "#{msg}");}
        io.puts 'retval = false;'
      end

      def emit_func_epilog(acc)
        io.indent 0 do
          io.puts "exit:"
        end
        emit_acc_ary_copy true if acc
        io.puts "return retval;"

        io.indent 0 do
          io.puts "error:"
        end

        io.puts 'retval = false;'
        io.puts 'goto exit;'
      end

      def emit_state(state)
        fail if state.nil?

        unemitted_states = []

        fail if state.ret? && !state.terminal?

        emit_body state, unemitted_states

        unemitted_states.each do |unemitted_state|
          emit_state unemitted_state
        end
      end

      def emit_body(state, unemitted_states, inlined = false)
        fail state.actions.inspect unless deterministic?(state)
        io.puts '/* begin inlined */' if inlined

        emit_label state unless inlined

        actions = state.actions.dup.reverse
        emit_actions state, actions, unemitted_states

        emit_ret state if state.ret?

        emit_transitions(state, unemitted_states)

        io.puts '/* end inlined */' if inlined
      end

      def emit_comment(state)
        io.puts "/* #{state.comment} (#{state.object_id}) */" if state.comment
      end

      def emit_label(state)
        io.indent 0 do
          io.puts "#{state_label state}:;"
        end
      end

      def has_else?(state)
        state.children.any? { |_, cond| cond == [:else] }
      end

      def emit_ret(state)
        io.puts "goto exit;"
      end

      def state_label(state, id = nil)
        "L#{id || id_map[state]}"
      end

      def emit_call(state, func)
        id = main_translator.request_func_call func, self

        func_call = call_to_c called_func_name(func, id),
                              [*params_args, inst_name_to_c(inst), '&acc'],
                              arch_prefix

        io.puts "if(!#{func_call}){goto error;}"
      end

      def emit_goto_transition(child)
        io.puts "goto #{state_label child};"
      end

      def emit_transitions(state, unemitted_states, &block)
        state
          .children
          .sort_by { |_, _, attrs| attrs[:priority] }
          .each do |child, expr|
          emit_cond expr do
            if inlineable?(child)
              block[] if block
              emit_body(child, unemitted_states, true)
              true
            else
              unemitted_states << child unless id_map.key?(child)
              block[] if block
              emit_goto_transition(child)
              false
            end
          end
        end

        fail 'missing else branch' if can_get_stuck?(state)
      end

      def can_get_stuck?(state)
        return false if state.ret?
        return false if has_else? state

        fail state.actions.inspect if state.children.empty?

        return false if state.children.any? do |_child, cond|
          cond.nil? || cond == [true]
        end

        true
      end

      def helper_call_to_c(name, args)
        prefix =
          if NO_ARCH_HELPERS.include?(name)
            nil
          else
            arch_prefix
          end

        call_to_c name, args, prefix
      end

      def simplify_helper(helper)
        simplified_helper = simplify_helper_ helper
        return simplified_helper if simplified_helper == helper
        simplify_helper simplified_helper
      end

      def simplify_helper_(helper)
        name, *args = helper
        case name
        when :neq
          [:not, [:eq, *args]]
        when :false?
          [:eq, *args, 0]
        when :true?
          [:not, [:false?, *args]]
        when :unset?
          [:not, [:set?, args[0]]]
        when :in?
          [:or, *args[1..-1].map { |arg| [:eq, args.first, arg] }]
        when :not_in?
          [:not, [:in?, *args]]
        else
          helper
        end
      end

      def emit_cond(cond, else_if: false, &block)
        cond_str =
          if cond.nil? || cond == true
            ''
          elsif cond[0] == :else
            'else '
          else
            "#{else_if ? 'else ' : ''}if(#{expr_to_c cond})"
          end

        emit_c_block cond_str, &block
      end

      def emit_log(_state, level, msg, *exprs)
        expr_part =
          if !exprs.empty?
            ", #{exprs.map { |expr| "(#{param_val_c_type}) #{expr_to_c expr}" }.join(', ')}"
          else
            ''
          end
        msg = msg.gsub('%', '%" EVOASM_PARAM_VAL_FORMAT "')
        io.puts %[evoasm_#{level}("#{msg}" #{expr_part});]
      end

      def emit_assert(_state, *expr)
        io.puts "assert(#{expr_to_c expr});"
      end

      def set_p_to_c(key, eol: false)
        call_to_c 'bitmap_get',
                  ["(#{bitmap_c_type} *) set_params", param_to_c(key)],
                  eol: eol
      end

      def get_to_c(key, eol: false)
        if local_param? key
          key.to_s
        else
          "param_vals[#{param_to_c(key)}]" + (eol ? ';' : '')
        end
      end

      def emit_set(_state, key, value, c_value: false)
        fail "setting non-local param '#{key}' is not allowed" unless local_param? key

        c_value =
          if c_value
            value
          else
            expr_to_c value
          end

        io.puts "#{key} = #{c_value};"
      end

      def merge_params(params)
        params.each do |param|
          register_param param
        end
      end

      def cmp_helper_to_c(name)
        case name
        when :eq then '=='
        when :gt then '>'
        when :lt then '<'
        when :gtq then '>='
        when :ltq then '<='
        else
          fail
        end
      end

      def infix_op_to_c(op, args)
        "(#{args.map { |a| expr_to_c a }.join(" #{op} ")})"
      end

      def emit_actions(state, actions, _unemitted_states)
        io.puts '/* actions */'
        until actions.empty?
          name, args = actions.last
          actions.pop
          send :"emit_#{name}", state, *args
        end
      end

      def deterministic?(state)
        n_children = state.children.size

        n_children <= 1 ||
          (n_children == 2 && has_else?(state))
      end

      def inlineable?(state)
        state.parents.size == 1 &&
          deterministic?(state.parents.first)
      end

      def emit_c_block(code = nil, &block)
        io.puts "#{code}{"
        io.indent do
          block[]
        end
        io.puts '}'
      end

      def emit_unordered_writes(state, param_name, writes)
        if writes.size > 1
          id, table_size = main_translator.request_pref_func writes, self
          func_name = pref_func_name(id)

          call_c = call_to_c(func_name,
                            [*params_args, param_name_to_c(param_name)],
                            arch_prefix)

          io.puts call_c, eol: ';'

          register_param param_name
          @param_domains[param_name] = (0..table_size - 1)
        elsif writes.size > 0
          cond, write_args = writes.first
          emit_cond cond do
            emit_write(state, *write_args)
          end
        end
      end

      def emit_read_access(state, op)
        call = access_call_to_c 'read', op, "#{arch_var_name(true)}->acc",
                                [inst && inst_name_to_c(inst) || 'inst']

        #emit_c_block "if(!#{call})" do
        #  emit_exit error: true
        #end
        io.puts call, eol: ';'
      end

      def access_call_to_c(name, op, acc = 'acc', params = [], eol: false)
        call_to_c("#{name}_access",
                  [
                    "(#{bitmap_c_type} *) &#{acc}",
                    "(#{regs.c_type}) #{expr_to_c(op)}",
                    *params
                  ],
                  indep_arch_prefix,
                  eol: eol)
      end

      def emit_write_access(_state, op)
        io.puts access_call_to_c('write', op, eol: true)
      end

      def emit_undefined_access(_state, op)
        io.puts access_call_to_c('undefined', op, eol: true)
      end

      def write_to_c(value, size)
        if size.is_a?(Array) && value.is_a?(Array)
          value_c, size_c = value.reverse.zip(size.reverse).inject(['0', 0]) do |(v_, s_), (v, s)|
            [v_ + " | ((#{expr_to_c v} & ((1 << #{s}) - 1)) << #{s_})", s_ + s]
          end
        else
          value_c =
            case value
            when Integer
              '0x' + value.to_s(16)
            else
              expr_to_c value
            end

          size_c = expr_to_c size
        end

        call_to_c "write#{size_c}", [value_c], indep_arch_prefix, eol: true
      end

      def emit_write(_state, value, size)
        io.puts write_to_c(value, size)
      end

      def emit_access(state, op, access)
        #access.each do |mode|
        #  case mode
        #  when :r
        #    emit_read_access state, op
        #  when :w
        #    emit_write_access state, op
        #  when :u
        #    emit_undefined_access state, op
        #  else
        #    fail "unexpected access mode '#{rw.inspect}'"
        #  end
        #end
      end

      def emit_inst_func(io, inst)
        @inst = inst
        with_io io do
          emit_func inst.name, inst.root_state, static: false
        end
      end

      def emit_called_func(io, func, id)
        with_io io do
          emit_func(called_func_name(func, id),
                    func.root_state,
                    {'inst' => inst_id_c_type, 'acc' => "#{acc_c_type} *"},
                    local_acc: false)
        end
      end

      def emit_pref_func(io, writes, id)
        with_io io do
          table_var_name, _table_size = main_translator.request_permutation_table writes.size
          func_name = name_to_c pref_func_name(id), arch_prefix

          emit_c_block "static void\n#{func_name}(#{arch_c_type} *#{arch_var_name},"\
            " #{params_c_args}, #{main_translator.param_names.c_type} order)" do
            io.puts 'int i;'
            emit_c_block "for(i = 0; i < #{writes.size}; i++)" do
              emit_c_block "switch(#{table_var_name}[param_vals[order]][i])" do
                writes.each_with_index do |write, index|
                  cond, write_args = write
                  emit_c_block "case #{index}:" do
                    emit_cond cond do
                      io.puts write_to_c(*write_args)
                    end
                    io.puts 'break;'
                  end
                end
                io.puts "default: evoasm_assert_not_reached();"
              end
            end
          end
        end
      end
    end

    class Translator < BaseTranslator
      attr_reader :params, :param_names
      attr_reader :id_map, :arch
      attr_reader :options
      attr_reader :features, :inst_flags
      attr_reader :reg_names, :exceptions
      attr_reader :reg_types, :operand_types
      attr_reader :bit_masks
      attr_reader :insts, :regs
      attr_reader :registered_param_domains

      STATIC_PARAMS = %i(reg0 reg1 reg2 reg3 reg4 imm operand_size address_size)
      PARAM_ALIASES = { imm0: :imm }

      def initialize(arch, insts, options = {})
        @arch = arch
        @insts = insts
        @pref_funcs = {}
        @called_funcs = {}
        @options = options
        @registered_param_domains = Set.new

        load_enums
      end

      def self.target_filename(arch, header: false)
        "evoasm-#{arch}.#{header ? 'h' : 'c'}"
      end

      def self.template_path(arch, header: false)
        File.join Evoasm.data, 'templates', "#{target_filename(arch, header: header)}.erb"
      end

      def translate!(&block)
        case arch
        when :x64
          translate_x64(&block)
        else
          fail "unsupported architecture #{@arch}"
        end
      end

      def main_translator
        self
      end

      def register_param(name)
        param_names.add name, PARAM_ALIASES[name]
      end

      def request_pref_func(writes, translator)
        _, table_size = request_permutation_table(writes.size)
        [request(@pref_funcs, writes, translator), table_size]
      end

      def request_func_call(func, translator)
        request @called_funcs, func, translator
      end

      def request_permutation_table(n)
        @permutation_tables ||= Hash.new { |h, k| h[k] = (0...k).to_a.permutation }
        [permutation_table_var_name(n), @permutation_tables[n].size]
      end

      private
      def load_enums
        @param_names = Enum.new :param_id, STATIC_PARAMS, prefix: arch

        case arch
        when :x64
          @features = Enum.new :feature, prefix: arch, flags: true
          @inst_flags = Enum.new :inst_flag, prefix: arch, flags: true
          @exceptions = Enum.new :exception_id, prefix: arch
          @reg_types = Enum.new :reg_type, Evoasm::Gen::X64::REGISTERS.keys, prefix: arch
          @operand_types = Enum.new :operand_type, Evoasm::Gen::X64::Inst::OPERAND_TYPES, prefix: arch
          @reg_names = Enum.new :reg_id, Evoasm::Gen::X64::REGISTER_NAMES, prefix: arch
          @bit_masks = Enum.new :bit_mask, %i(rest 64_127 32_63 0_31), prefix: arch, flags: true
        end
      end

      def register_param_domain(domain)
        @registered_param_domains << domain
      end

      def translate_x64(&block)
        translate_x64_c(&block)

        # NOTE: must be done after
        # translating C file
        # as we are collecting information
        # in the translation process
        translate_x64_h(&block)
      end

      def translate_x64_h(&block)
        target_filename = self.class.target_filename(arch, header: true)
        template_path = self.class.template_path(arch, header: true)

        renderer = Erubis::Eruby.new(File.read(template_path))
        block[target_filename, renderer.result(binding)]
      end

      def translate_x64_c(&block)
        target_filename = self.class.target_filename(arch)
        template_path = self.class.template_path(arch)

        # NOTE: keep in correct order
        inst_funcs = inst_funcs_to_c
        pref_funcs = pref_funcs_to_c
        permutation_tables = permutation_tables_to_c
        called_funcs = called_funcs_to_c
        insts_c = insts_to_c
        inst_operands = inst_operands_to_c
        inst_params = inst_params_to_c
        param_domains = param_domains_to_c

        renderer = Erubis::Eruby.new(File.read(template_path))
        block[target_filename, renderer.result(binding)]
      end

      def operand_c_type
        name_to_c :operand, arch_prefix
      end

      def param_c_type
        name_to_c :arch_param
      end

      def inst_params_var_name(inst)
        "params_#{inst.name}"
      end

      def insts_var_name
        "_evoasm_#{arch}_insts"
      end

      def inst_operands_var_name(inst)
        "operands_#{inst.name}"
      end

      def inst_param_domains_var_name(inst)
        "domains_#{inst.name}"
      end

      def param_domain_var_name(domain)
        case domain
        when Range
          "param_domain__#{domain.begin.to_s.tr('-', 'm')}_#{domain.end}"
        when Array
          "param_domain_enum__#{domain.join '_'}"
        else
          fail "unexpected domain type #{domain.class} (#{domain.inspect})"
        end
      end

      def permutation_table_var_name(n)
        "permutations#{n}"
      end

      def inst_encode_func_name(inst)
        name_to_c inst.name, arch_prefix
      end

      def inst_funcs_to_c(io = StrIO.new)
        @inst_translators = insts.map do |inst|
          @features.add_all inst.features
          @inst_flags.add_all inst.flags
          @exceptions.add_all inst.exceptions

          inst_translator = FuncTranslator.new arch, self
          inst_translator.emit_inst_func io, inst

          inst_translator
        end

        io.string
      end

      def permutation_tables_to_c(io = StrIO.new)
        Hash(@permutation_tables).each do |n, perms|
          io.puts "static int #{permutation_table_var_name n}"\
                    "[#{perms.size}][#{perms.first.size}] = {"

          perms.each do |perm|
            io.puts "  {#{perm.join ', '}},"
          end
          io.puts '};'
          io.puts
        end

        io.string
      end

      def called_funcs_to_c(io = StrIO.new)
        @called_funcs.each do |func, (id, translators)|
          func_translator = FuncTranslator.new arch, self
          func_translator.emit_called_func io, func, id

          translators.each do |translator|
            translator.merge_params func_translator.registered_params
          end
        end

        io.string
      end

      def inst_to_c(io, inst, params)
        io.puts '{'
        io.indent do
          io.puts '{'
          io.indent do
            io.puts inst_name_to_c(inst), eol: ','
            io.puts params.size, eol: ','
            if params.empty?
              io.puts "NULL,"
            else
              io.puts "(#{param_c_type} *)" + inst_params_var_name(inst), eol: ','
            end
            io.puts '(evoasm_inst_encode_func)' + inst_encode_func_name(inst), eol: ','
          end
          io.puts '},'

          io.puts "#{features_bitmap(inst)}ull", eol: ','
          if inst.operands.empty?
            io.puts 'NULL,'
          else
            io.puts "(#{operand_c_type} *)#{inst_operands_var_name inst}", eol: ','
          end
          io.puts inst.operands.size, eol: ','
          io.puts exceptions_bitmap(inst), eol: ','
          io.puts inst_flags_to_c(inst)
        end
        io.puts '},'
      end

      def insts_to_c(io = StrIO.new)
        io.puts "static const evoasm_x64_inst #{insts_var_name}[] = {"
        @inst_translators.each do |translator|
          inst_to_c io, translator.inst, translator.registered_params
        end
        io.puts '};'

        io.string
      end

      def inst_param_to_c(io, inst, params, param_domains)
        if !params.empty?
          io.puts "static const #{param_c_type} #{inst_params_var_name inst}[] = {"
          io.indent do
            params.each do |param|
              next if local_param? param

              param_domain = param_domains[param] || inst.param_domain(param)
              register_param_domain param_domain

              io.puts '{'
              io.indent do
                io.puts param_name_to_c(param), eol: ','
                io.puts '(evoasm_domain *) &' + param_domain_var_name(param_domain)
              end
              io.puts '},'
            end
          end
          io.puts '};'
          io.puts
        end
      end

      def inst_params_to_c(io = StrIO.new)
        @inst_translators.each do |translator|
          inst_param_to_c io, translator.inst, translator.registered_params, translator.param_domains
        end

        io.string
      end

      def inst_operand_to_c(translator, op, io = StrIO.new, eol:)
        io.puts '{'
        io.indent do
          io.puts op.access.include?(:r) ? '1' : '0', eol: ','
          io.puts op.access.include?(:w) ? '1' : '0', eol: ','
          io.puts op.access.include?(:u) ? '1' : '0', eol: ','
          io.puts op.access.include?(:c) ? '1' : '0', eol: ','
          io.puts op.implicit? ? '1' : '0', eol: ','

          params = translator.registered_params.reject{|p| local_param? p}
          if op.param
            param_idx = params.index(op.param) or \
              raise "param #{op.param} not found in #{translator.params.inspect}" \
                      " (#{translator.inst.mnem}/#{translator.inst.index})"

            io.puts param_idx, eol: ','
          else
            io.puts params.size, eol: ','
          end

          io.puts operand_type_to_c(op.type), eol: ','

          if op.size
            io.puts operand_size_to_c(op.size), eol: ','
          else
            io.puts 'EVOASM_N_OPERAND_SIZES', eol: ','
          end

          if op.reg
            io.puts reg_name_to_c(op.reg), eol: ','
          else
            io.puts reg_names.n_elem_to_c, eol: ','
          end

          if op.reg_type
            io.puts reg_type_to_c(op.reg_type), eol: ','
          else
            io.puts reg_types.n_elem_to_c, eol: ','
          end

          if op.accessed_bits.key? :w
            io.puts bit_mask_to_c(op.accessed_bits[:w])
          else
            io.puts bit_masks.all_to_c
          end
        end
        io.puts '}', eol: eol
      end

      def inst_operands_to_c(io = StrIO.new)
        @inst_translators.each do |translator|
          if !translator.inst.operands.empty?
            io.puts "static const #{operand_c_type} #{inst_operands_var_name translator.inst}[] = {"
            io.indent do
              translator.inst.operands.each do |op|
                inst_operand_to_c(translator, op, io, eol: ',')
              end
            end
            io.puts '};'
            io.puts
          end
        end

        io.string
      end

      ENUM_MAX_LENGTH = 32
      def param_domain_to_c(io, domain, index)
        domain_c =
          case domain
          when (:INT64_MIN..:INT64_MAX)
            "{EVOASM_DOMAIN_TYPE_INTERVAL64, #{index}, #{0}, #{0}}"
          when Range
            min_c = expr_to_c domain.begin
            max_c = expr_to_c domain.end
            "{EVOASM_DOMAIN_TYPE_INTERVAL, #{index}, #{min_c}, #{max_c}}"
          when Array
            if domain.size > ENUM_MAX_LENGTH
              raise 'enum exceeds maximal enum length of'
            end
            values_c = "#{domain.map { |expr| expr_to_c expr }.join ', '}"
            "{EVOASM_DOMAIN_TYPE_ENUM, #{index}, #{domain.length}, {#{values_c}}}"
          end

        domain_c_type =
          case domain
          when Range
            'evoasm_interval'
          when Array
            "evoasm_enum#{domain.size}"
          end
        io.puts "static const #{domain_c_type} #{param_domain_var_name domain} = #{domain_c};"
      end

      def param_domains_to_c(io = StrIO.new)
        registered_param_domains.each_with_index do |domain, index|
          param_domain_to_c io, domain, index
        end

        io.puts "const uint16_t evoasm_n_domains = #{registered_param_domains.size};"

        io.string
      end

      def request(hash, key, translator)
        id, translators = hash[key]
        if id.nil?
          id = hash.size
          translators = []

          hash[key] = [id, translators]
        end

        translators << translator
        id
      end

      def pref_funcs_to_c(io = StrIO.new)
        @pref_funcs.each do |writes, (id, translators)|
          func_translator = FuncTranslator.new arch, self
          func_translator.emit_pref_func io, writes, id

          translators.each do |translator|
            translator.merge_params func_translator.registered_params
          end
        end

        io.string
      end

      def inst_flags_to_c(inst)
        if inst.flags.empty?
          "0"
        else
          inst.flags.map { |flag| inst_flag_to_c flag }
              .join ' | '
        end
      end

      def features_bitmap(inst)
        bitmap(features) do |flag, index|
          inst.features.include?(flag)
        end
      end

      def exceptions_bitmap(inst)
        bitmap(exceptions) do |flag, index|
          inst.exceptions.include?(flag)
        end
      end

      def bitmap(enum, &block)
        enum.keys.each_with_index.inject(0) do |acc, (flag, index)|
          if block[flag, index]
            acc | (1 << index)
          else
            acc
          end
        end
      end

    end
  end
end
