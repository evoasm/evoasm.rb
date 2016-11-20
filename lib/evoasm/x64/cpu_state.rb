require 'evoasm/x64'

module Evoasm
  module X64
    class CPUState < FFI::AutoPointer
      def self.release(ptr)
        Libevoasm.x64_cpu_state_destroy(ptr)
        Libevoasm.x64_cpu_state_free(ptr)
      end

      def initialize(*flags)
        flags << :rflags unless flags.include?(:rflags)

        ptr = Libevoasm.x64_cpu_state_alloc
        Libevoasm.x64_cpu_state_init ptr, Libevoasm.enum_type(:x64_cpu_state_flags).flags(flags, shift: false)
        super(ptr)
      end

      def set(register, data)
        data = Array(data)
        ptr = FFI::MemoryPointer.new :uint64, data.size
        ptr.write_array_of_uint64 data
        Libevoasm.x64_cpu_state_set self, register, ptr, data.size
      end

      def get(register, word = :none)
        data_ptr = FFI::MemoryPointer.new :uint64, 16
        data_len = Libevoasm.x64_cpu_state_get self, register, word, data_ptr, 16
        data_ptr.read_array_of_uint64 data_len
      end

      def clone
        cloned_cpu_state = self.class.new
        Libevoasm.x64_cpu_state_clone self, cloned_cpu_state

        cloned_cpu_state
      end

      def xor(other)
        xored = self.class.new
        Libevoasm.x64_cpu_state_xor self, other, xored
        xored
      end

      def to_h
        X64.registers.each_with_object({}) do |register, hash|
          hash[register] = get(register)
        end
      end

      def get_rflags_flag(flag)
        Libevoasm.x64_cpu_state_get_rflags_flag self, flag
      end

      def emit_store(buffer)
        unless Libevoasm.x64_cpu_state_emit_store self, buffer
          raise Error.last
        end
      end

      def emit_load(buffer)
        unless Libevoasm.x64_cpu_state_emit_load self, buffer
          raise Error.last
        end
      end
    end
  end
end
