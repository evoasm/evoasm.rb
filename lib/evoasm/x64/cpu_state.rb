require 'evoasm/x64'

module Evoasm
  module X64
    # Represents the CPU state (i.e. a snapshot of all registers)
    # at a specific moment in time.
    class CPUState < FFI::AutoPointer

      # @!visibility private
      def self.release(ptr)
        Libevoasm.x64_cpu_state_destroy(ptr)
        Libevoasm.x64_cpu_state_free(ptr)
      end

      # @param flags [Array<Symbol>]
      def initialize(flags = [:rflags])
        ptr = Libevoasm.x64_cpu_state_alloc
        Libevoasm.x64_cpu_state_init ptr, Libevoasm.enum_type(:x64_cpu_state_flags).flags(flags, shift: false)
        super(ptr)
      end

      def self.random
        cpu_state = new
        Libevoasm.x64_cpu_state_rand cpu_state, PRNG.default

        cpu_state
      end

      # Sets the value of a register
      # @param register [Symbol] register to set
      # @param data [Array<Integer>, Integer] value as a single 64-bit integer or an array of multiple
      #   64-bit integers (e.g. for vector registers)
      # @return [void]
      def []=(register, data)
        data = Array(data)
        ptr = FFI::MemoryPointer.new :uint64, data.size
        ptr.write_array_of_uint64 data
        Libevoasm.x64_cpu_state_set self, register, ptr, data.size
      end

      # Obtain the value of a register
      # @param register [Symbol] the register
      # @param word [Symbol] an optional word to mask the value (e.g. to obtain a subregister value)
      # @return [Array<Integer>] the register's value as an array of 64-bit integers
      def [](register, word = :none)
        data_ptr = FFI::MemoryPointer.new :uint64, 16
        data_len = Libevoasm.x64_cpu_state_get self, register, word, data_ptr, 16
        data_ptr.read_array_of_uint64 data_len
      end

      # Clone this CPU state object
      # @return [CPUState] the cloned object
      def clone
        cloned_cpu_state = self.class.new
        Libevoasm.x64_cpu_state_clone self, cloned_cpu_state

        cloned_cpu_state
      end

      # @!visibility private
      def xor(other)
        xored = self.class.new
        Libevoasm.x64_cpu_state_xor self, other, xored
        xored
      end

      # @!visibility private
      def distance(other, metric = :absdiff)
        Libevoasm.x64_cpu_state_calc_dist self, other, metric
      end

      # Converts this object into a hash
      # @return [Hash] the hash
      def to_h
        X64.registers.each_with_object({}) do |register, hash|
          hash[register] = self[register]
        end
      end

      def get_rflags_flag(flag)
        Libevoasm.x64_cpu_state_get_rflags_flag self, flag
      end

      # Emits machine code to store (save) the current CPU state
      # into this object
      # @param buffer [Buffer] the buffer to emit to
      # @return [void]
      # @raise [Error] if an error occurres
      def emit_store(buffer)
        unless Libevoasm.x64_cpu_state_emit_store self, buffer
          raise Error.last
        end
      end

      # Emits machine code to load (set) the current CPU state to
      # the state of this object
      # @param buffer [Buffer] the buffer to emit to
      # @return [void]
      # @raise [Error] if an error occurres
      def emit_load(buffer)
        unless Libevoasm.x64_cpu_state_emit_load self, buffer
          raise Error.last
        end
      end
    end
  end
end
