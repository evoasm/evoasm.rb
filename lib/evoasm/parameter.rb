module Evoasm
  class Parameter < FFI::Pointer
    def id
      Libevoasm.param_id self
    end

    def domain
      Libevoasm.param_domain(self).to_ruby
    end
  end
end
