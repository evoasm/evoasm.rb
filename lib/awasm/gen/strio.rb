module Awasm
  module Gen
    class StrIO < ::StringIO
      def indent(indent = nil)
        @indent ||= 0

        prev_indent = @indent
        @indent = indent || @indent + 1
        yield
        @indent = prev_indent
      end

      def indent_str
        '  ' * @indent
      end

      def puts(line = nil, eol: '')
        if line
          write indent_str if @indent
          super("#{line}#{eol}")
        else
          super()
        end
      end
    end
  end
end
