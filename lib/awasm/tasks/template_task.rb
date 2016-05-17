require 'rake'
require 'yaml'

module Awasm
  module Tasks
    class TemplateTask < Rake::TaskLib
      attr_reader :name

      ALL_ARCHS = %i(x64)
      X64_TABLE_FILENAME = File.join(Awasm.data, 'tables', 'x64.csv')
      ARCH_TABLES = {
        x64: X64_TABLE_FILENAME
      }

      def initialize(name = 'awasm:gen', &block)
        @ruby_bindings = true
        @name = name
        @archs = ALL_ARCHS

        block[self] if block

        define
      end

      def define
        deps = []

        namespace 'awasm:templates' do
          yml_filename = ext_path('tmpls.yml')
          tmpls = YAML.load File.read(yml_filename)
          tmpls.each_value do |tmpl|
            srcs = Array(tmpl['src']).map{|f| ext_path f}
            dsts = Array(tmpl['dst']).map{|f| ext_path f}
            srcs.zip(dsts).each do |src, dst|
              deps << dst
              file dst => [src, yml_filename] do
                data = File.read src

                tmpl['locals'].sort_by{|k, _| k.length }.reverse.each do |name, value|
                  p name
                  data.gsub! "$#{name}", value.to_s
                end
                File.write dst, data
              end
            end
          end
        end
        task 'awasm:templates' => deps
      end

      def ext_path(filename)
        File.join Awasm.root, 'ext', 'awasm_native', filename
      end
    end
  end
end
