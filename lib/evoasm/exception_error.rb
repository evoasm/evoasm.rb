module Evoasm
  class ExceptionError < StandardError

    attr_reader :exception_name
    attr_reader :architecture

    def initialize(architecture, exception_name)
      @architecture = architecture
      @exception_name = exception_name

      super("#{exception_name} was signalled")
    end
  end
end