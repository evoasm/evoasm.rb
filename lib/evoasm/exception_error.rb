module Evoasm
  # Represents a hardware exception (e.g. division by zero).
  class ExceptionError < StandardError

    # @return [Symbol] the exception name
    attr_reader :exception_name

    # @return [Symbol] the architecture
    attr_reader :architecture

    # @!visibility private
    def initialize(architecture, exception_name)
      @architecture = architecture
      @exception_name = exception_name

      super("#{exception_name} was signalled")
    end
  end
end