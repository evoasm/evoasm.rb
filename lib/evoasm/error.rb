module Evoasm
  # Represents an low-level error (originating from the backend library).
  class Error < StandardError

    # @return [Integer] the line number at which this error occurred
    attr_reader :line

    # @return [Symbol] the error type
    attr_reader :type

    # @return [Symbol] the error code
    attr_reader :code

    # @return [String] the filename of the source file this error occurred in
    attr_reader :filename

    # @!visibility private
    def self.last
      self.new(Libevoasm.get_last_error)
    end

    # @!visibility private
    def initialize(ptr)
      message = Libevoasm.error_get_msg ptr

      @type = Libevoasm.error_get_type ptr
      @code = Libevoasm.error_get_code ptr
      @filename = Libevoasm.error_get_filename ptr
      @line = Libevoasm.error_get_line ptr

      super(message)
    end

    # @!visibility private
    def backtrace
      backtrace = super
      backtrace.unshift "#{@filename}:#{@line}" if backtrace
      backtrace
    end
  end
end
