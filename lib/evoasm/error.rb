module Evoasm
  class Error < StandardError

    attr_reader :line, :type, :code, :filename

    def self.last
      self.new(Libevoasm.last_error)
    end

    def initialize(ptr)
      message = Libevoasm.error_msg ptr

      @type = Libevoasm.error_type ptr
      @code = Libevoasm.error_code ptr
      @filename = Libevoasm.error_filename ptr
      @line = Libevoasm.error_line ptr

      super(message)
    end

    def backtrace
      backtrace = super
      backtrace.unshift "#{@filename}:#{@line}" if backtrace
      backtrace
    end
  end
end
