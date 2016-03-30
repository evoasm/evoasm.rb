require 'awasm'
require 'awasm/gen/state'
require 'awasm/gen/translator'

require 'rake'

module Awasm
  module Gen
    class Task < Rake::TaskLib
      HEADER_N_LINES = 15
      CSV_SEPARATOR = ';'

      attr_accessor :ruby_bindings
      attr_reader :name, :archs

      ALL_ARCHS = %i(x64)

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
            prereqs, insts = prepare arch
            translator = Translator.new(arch, insts, ruby: ruby_bindings)

            prereqs << translator.template_path
            target_path = ext_path(translator.target_filename)

            file target_path => prereqs do
              puts "Translating"
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

      def prepare(arch)
        send :"prepare_#{arch}"
      end

      X64_TABLE_FILENAME = File.join(Awasm.data, 'tables', 'x64.csv')
      def prepare_x64
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

        [[X64_TABLE_FILENAME], X64::Inst.load(rows)]
      end
    end
  end
end
