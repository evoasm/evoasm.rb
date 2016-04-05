module Awasm
  module Gen
    module NameUtil
      def namespace
        'awasm'
      end

      def const_name_to_c(name, prefix)
        name_to_c name, prefix, const: true
      end

      def name_to_c(name, prefix = nil, const: false)
        c_name = [namespace, *prefix, name.to_s.sub(/\?$/, '')].compact.join '_'
        if const
          c_name.upcase
        else
          c_name
        end
      end

      def indep_arch_prefix(name = nil)
        ['arch', name]
      end

      def arch_prefix(name = nil)
        [arch, name]
      end

      def error_code_to_c(name)
        prefix = name == :ok ? :error_code : indep_arch_prefix(:error_code)
        const_name_to_c name, prefix
      end

      def reg_name_to_c(name)
        const_name_to_c name, arch_prefix(:reg)
      end

      def exception_to_c(name)
        const_name_to_c name, arch_prefix(:exception)
      end

      def reg_type_to_c(name)
        const_name_to_c name, arch_prefix(:reg_type)
      end

      def operand_type_to_c(name)
        const_name_to_c name, arch_prefix(:operand_type)
      end

      def inst_name_to_c(inst)
        const_name_to_c inst.name, arch_prefix(:inst)
      end

      def operand_size_to_c(size)
        const_name_to_c size, :operand_size
      end

      def feature_name_to_c(name)
        const_name_to_c name, arch_prefix(:feature)
      end

      def inst_flag_to_c(flag)
        const_name_to_c flag, arch_prefix(:inst_flag)
      end

      def param_name_to_c(name)
        const_name_to_c name, arch_prefix(:param)
      end
    end
  end
end
