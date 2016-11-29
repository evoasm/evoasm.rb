require 'evoasm/domain'

module Evoasm
  # Base class for all parameters.
  class Parameter < FFI::Pointer

    # @return [Integer] a numeric identifier for this parameter
    def id
      Libevoasm.param_get_id self
    end

    # @return [Domain] the domain associated with this parameter
    def domain
      domain = Domain.wrap Libevoasm.param_get_domain(self)
      domain.autorelease = false

      domain
    end
  end
end
