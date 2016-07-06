require 'rake'
require 'yaml'

module Evoasm
  module Tasks
    class TemplateTask < Rake::TaskLib
      attr_accessor :source
      attr_accessor :target
      attr_accessor :subs

      class << self
        attr_reader :all
      end
      @all = []

      def initialize(&block)
        block[self] if block
        define
      end

      def define
        srcs = Array(source).map { |f| ext_path f }
        dsts = Array(target).map { |f| gen_path f }
        srcs.zip(dsts).each do |src, dst|
          file dst => src do
            data = File.read src
            subs.sort_by{|k, _| k.length }.reverse.each do |name, value|
              data.gsub! "$#{name}", value.to_s
              data.gsub! "$#{name.upcase}", value.to_s.upcase
              p "$-#{name}"
              data.gsub! "$-#{name}", value.to_s.gsub('_', '-')
            end
            File.write dst, data
          end
          self.class.all << dst
        end
      end

      def ext_dir
        File.join Evoasm.root, 'ext', 'evoasm_ext'
      end

      def ext_path(filename)
        File.join ext_dir, filename
      end

      def gen_path(filename)
        File.join ext_dir, 'gen', filename
      end
    end
  end
end
