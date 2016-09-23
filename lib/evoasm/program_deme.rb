require 'evoasm/program'
require 'evoasm/error'
require 'evoasm/deme'
require 'evoasm/program'

module Evoasm
  class ProgramDeme < Deme

    def initialize(architecture, parameters = nil, &block)
      @parameters = parameters || Parameters.new(architecture)
      block[@parameters] if block

      ptr = Libevoasm.program_deme_alloc
      unless Libevoasm.program_deme_init ptr, architecture, @parameters
        raise Error.last
      end

      super(ptr)
    end

    def self.release(ptr)
      Libevoasm.program_deme_destroy(ptr)
      Libevoasm.program_deme_free(ptr)
    end

    private

    def new_individual(ptr)
      program = Program.new
      unless Libevoasm.program_deme_get_program(self, ptr, program)
        raise Error.last
      end

      program
    end
  end
end

require 'evoasm/program_deme/parameters'
