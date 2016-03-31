require 'awasm'
require 'awasm/gen/state'
require 'awasm/gen/translator'

require 'rake'

module Awasm
  module Gen
    class Task < Rake::TaskLib
      HEADER_N_LINES = 15
      CSV_SEPARATOR = ','

      attr_accessor :ruby_bindings
      attr_reader :name, :archs

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
        namespace 'awasm:gen' do
          archs.each do |arch|
            prereqs = [ARCH_TABLES[arch]]

            prereqs << Translator.template_path(arch)
            target_path = ext_path(Translator.target_filename(arch))

            file target_path => prereqs do
              puts "Translating"
              insts = load_insts arch
              translator = Translator.new(arch, insts, ruby: ruby_bindings)
              translator.translate! do |filename, content|
                File.write ext_path(filename), content
              end
            end

            task "translate:#{arch}" => target_path
          end

          task 'translate' => archs.map { |arch| "translate:#{arch}" }
        end

        task name => 'gen:translate'
      end

      def ext_path(filename)
        File.join Awasm.root, 'ext', 'awasm_native', filename
      end

      def load_insts(arch)
        send :"load_#{arch}_insts"
      end

      def load_x64_insts
        require 'awasm/gen/x64/inst'

        rows = []
        File.open X64_TABLE_FILENAME do |file|
          file.each_line.with_index do |line, line_idx|
            # header
            next if line_idx == 0

            row = line.split(CSV_SEPARATOR)
            rows << row
          end
        end

        X64::Inst.load(rows)
      end
    end
  end
end
