require 'evoasm/program'
require 'evoasm/error'
require 'evoasm/deme'

module Evoasm
  class ProgramDeme < Deme

    def initialize(architecture, parameters = nil, &block)
      @parameters = parameters || Parameters.new(architecture)
      block[@parameters] if block

      ptr = Libevoasm.program_deme_alloc
      a = Libevoasm.program_deme_init ptr, architecture, @parameters
      unless a
        raise Error.last
      end

      super(ptr)
    end

    def self.release(ptr)
      Libevoasm.program_deme_destroy(ptr)
      Libevoasm.program_deme_free(ptr)
    end
  end
end

require 'evoasm/program_deme/parameters'
