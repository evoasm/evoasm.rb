module Evoasm
  class Error < StandardError
    attr_reader :type, :line, :filename

    def self.last
      self.new(Libevoasm.last_error)
    end

    def initialize(error)
      super(error[:msg].to_s)
      @line = error[:line]
      @type = error[:type]
      @filename = error[:filename].to_s
    end

    def backtrace
      backtrace = super
      backtrace.unshift "#{@filename}:#{@line}" if backtrace
      backtrace
    end
  end
end
