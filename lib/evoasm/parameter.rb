require 'evoasm/domain'

module Evoasm
  class Parameter < FFI::Pointer
    def id
      Libevoasm.param_get_id self
    end

    def domain
      domain = Domain.wrap Libevoasm.param_get_domain(self)
      domain.autorelease = false

      domain
    end
  end
end
