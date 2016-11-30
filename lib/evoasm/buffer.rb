require 'evoasm/exception_error'

module Evoasm
  # Represents an executable area of memory
  class Buffer < FFI::AutoPointer

    # @!visibility private
    def self.release(ptr)
      Libevoasm.buf_destroy(ptr)
      Libevoasm.buf_free(ptr)
    end

    # @param capacity [Integer] the buffer's capacity in bytes
    # @param type [:mmap, :malloc] the buffer type, only buffers created with +:mmap+ are executable
    def initialize(capacity, type = :mmap)
      ptr = Libevoasm.buf_alloc
      unless Libevoasm.buf_init ptr, type, capacity
        Libevoasm.buf_free ptr
        raise Error.last
      end
      super(ptr)
    end

    # @!attribute [r] capacity
    # @return [Integer] the buffer's capacity
    def capacity
      Libevoasm.buf_get_capa self
    end

    # @!attribute [r] position
    # @return [Integer] the buffer cursor's current position
    def position
      Libevoasm.buf_get_pos self
    end

    # Resets the buffers position to zero
    # @return [void]
    def reset
      Libevoasm.buf_reset self
    end

    # @!attribute [r] type
    # @return [:mmap, :malloc] the buffer's current position
    def type
      Libevoasm.buf_get_type self
    end

    # Gives the buffer's content as string
    # @return [String]
    def to_s
      ptr = Libevoasm.buf_get_data self
      ptr.read_string capacity
    end

    # @!visibility private
    def __log__(log_level)
      Libevoasm.buf_log self, log_level
    end

    # Writes data into the buffer and advances the buffer position
    # @param data [String] the data to write into the buffer
    def write(data)
      data_ptr = FFI::MemoryPointer.new :uint8, data.size
      data_ptr.write_string data

      if Libevoasm.buf_write(self, data_ptr, data.size) != 0
        raise Error.last
      end
    end

    # Executes the buffer's content.
    # @raise [ExceptionError] if a hardware exception occurred
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
  end
end
