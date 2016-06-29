require 'evoasm'
require 'evoasm/gen/state'
require 'evoasm/gen/translator'

require 'rake'

module Evoasm
  module Tasks
    class GenTask < Rake::TaskLib
      include Evoasm::Gen

      HEADER_N_LINES = 15
      CSV_SEPARATOR = ','

      attr_accessor :ruby_bindings
      attr_reader :name, :archs

      ALL_ARCHS = %i(x64)
      X64_TABLE_FILENAME = File.join(Evoasm.data, 'tables', 'x64.csv')
      ARCH_TABLES = {
        x64: X64_TABLE_FILENAME
      }

      def initialize(name = 'evoasm:gen', &block)
        @ruby_bindings = true
        @name = name
        @archs = ALL_ARCHS

        block[self] if block

        define
      end

      def define
        namespace 'evoasm:gen' do
          archs.each do |arch|
            prereqs = [ARCH_TABLES[arch]]

            prereqs << Translator.template_path(arch)
            target_path = gen_path(Translator.target_filename(arch))

            file target_path => prereqs do
              puts "Translating"
              insts = load_insts arch
              translator = Translator.new(arch, insts, ruby: ruby_bindings)
              translator.translate! do |filename, content|
                File.write gen_path(filename), content
              end
            end

            task "translate:#{arch}" => target_path
          end

          task 'translate' => archs.map { |arch| "translate:#{arch}" }
        end

        task name => 'gen:translate'
      end

      def gen_path(filename)
        File.join Evoasm.root, 'ext', 'evoasm_native', filename
      end

      def load_insts(arch)
        send :"load_#{arch}_insts"
      end

      def load_x64_insts
        require 'evoasm/gen/x64/inst'

        rows = []
        File.open X64_TABLE_FILENAME do |file|
          file.each_line.with_index do |line, line_idx|
            # header
            next if line_idx == 0

            row = line.split(CSV_SEPARATOR)
            rows << row
          end
        end

        Gen::X64::Inst.load(rows)
      end
    end
  end
end
