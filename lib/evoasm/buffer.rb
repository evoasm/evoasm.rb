module Evoasm
  class Buffer < FFI::AutoPointer
    def self.release(ptr)
      Libevoasm.buf_destroy(buf)
      Libevoasm.buf_free(buf)
    end

    def initialize(type, capacity)
      ptr = Libevoasm.buf_alloc
      unless Libevoasm.buf_init ptr, type, capacity
        raise Error.last
      end
      super(ptr)
    end

    def capacity
      Libevoasm.buf_get_capa self
    end

    def position
      Libevoasm.buf_get_pos self
    end

    def type
      Libevoasm.buf_get_type self
    end

    def to_s
      ptr = Libevoasm.buf_get_data self
      ptr.read_string capacity
    end

    def __log__(log_level)
      Libevoasm.buf_log self, log_level
    end

    def execute!
      begin
        unless Libevoasm.buf_protect self, :rx
          raise Error.last
        end
        return_value = Libevoasm.buf_exec(self)
      ensure
        unless Libevoasm.buf_protect self, :rw
          raise Error.last
        end
      end
      return return_value
    end

    def execute_and_return!

    end
  end
end
