require 'evoasm/exception_error'

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

        current_arch = Libevoasm.get_current_arch
        return_value = nil
        exception_enum = Libevoasm.enum_type(:"#{current_arch}_exception")
        # catch everything
        exception_mask = exception_enum.flags(exception_enum.symbols, shift: true)

        #FIXME: should be intptr_t, but FFI sucks
        return_value_ptr = FFI::MemoryPointer.new :size_t, 1

        success = Libevoasm.buf_safe_exec(self, exception_mask, return_value_ptr)
        return_value = return_value_ptr.read_size_t


        if success
          return return_value
        else
          raise ExceptionError.new(current_arch, exception_enum[return_value])
        end
      ensure
        unless Libevoasm.buf_protect self, :rw
          raise Error.last
        end
      end
    end

    private
    def safe_execute!(exceptions)
      current_arch = Libevoasm.get_current_arch
      exception_enum = Libevoasm.enum_type(:"#{current_arch}_exception")

      exception_mask = exception_enum.flags(exceptions, shift: true)

      #FIXME: should be intptr_t, but FFI sucks
      return_value_ptr = FFI::MemoryPointer.new :size_t, 1

      if Libevoasm.buf_safe_exec(self, exception_mask, return_value_ptr)
        return_value_ptr.read_size_t
      else
        nil
      end
    end
  end
end
