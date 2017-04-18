require 'ffi'

module Evoasm

  # Represents a kernel comprising one ore multiple kernels
  class Kernel < FFI::AutoPointer

    require_relative 'kernel/io.rb'

    private_class_method :new

    def self.wrap(ptr)
      new ptr
    end

    # @!visibility private
    def self.release(ptr)
      Libevoasm.kernel_destroy(ptr)
      Libevoasm.kernel_free(ptr)
    end

    # Runs the kernel with the given input
    # @param input_tuple [Array] an input tuple
    # @return [Array] the output tuple corresponding to the given input
    def run(*input_tuple)
      run_all(input_tuple).first
    end

    # Gives the input arity, i.e. the number of arguments
    # @return [Integer] arity
    def input_arity
      Libevoasm.kernel_get_input_arity self
    end

    # Gives the output arity, i.e. the number of return values
    # @return [Integer] arity
    def output_arity
      Libevoasm.kernel_get_output_arity self
    end

    # Gives the kernel's input type
    # @example
    #   kernel.input_type #=> [:i64x1]
    # @return [Array<Symbol>] the input type
    def input_types
      Array.new(self.input_arity) do |index|
        Libevoasm.kernel_get_input_type self, index
      end
    end

    # Gives the kernel's output type
    # @example
    #   kernel.output_type #=> [:i64x1]
    # @return [Array<Symbol>] the output type
    def output_types
      Array.new(self.output_arity) do |index|
        Libevoasm.kernel_get_output_type self, index
      end
    end

    # Like {#run}, but runs multiple input tuples at once
    # @param input_examples [Array] an array of input tuples
    # @return [Array] an array of output tuples
    def run_all(*input_examples)
      input = Kernel::Input.new(input_examples, self.input_types)

      output_ptr = Libevoasm.kernel_io_alloc
      success = Libevoasm.kernel_run self, input, output_ptr

      unless success
        raise Error.last
      end

      Kernel::Output.new(output_ptr, self.output_types).to_a
    end

    # Gives the size of the kernel as the number of instructions
    # @return [Integer] size
    def size
      Libevoasm.kernel_get_size self
    end

    # Eliminates intron instructions (instructions without effect)
    # @return [Kernel] a new kernel with introns eliminated
    def eliminate_introns
      kernel = Libevoasm.kernel_alloc
      unless Libevoasm.kernel_elim_introns self, kernel
        raise Error.last
      end

      self.class.wrap kernel
    end

    # Gives the disassembly for the specified kernel
    # @param kernel_index [Integer] index of kernel to disassemble
    # @return [String] disassembly
    def disassemble_kernel(kernel_index)
      code_ptr_ptr = FFI::MemoryPointer.new :pointer
      code_len = Libevoasm.kernel_get_kernel_code self, kernel_index, code_ptr_ptr
      code_ptr = code_ptr_ptr.read_pointer
      code = code_ptr.read_string(code_len)

      X64.disassemble code, code_ptr.address
    end

    # Gives the disassembly for all kernels in the kernel
    # @return [Array<String>] array of disassembly
    def disassemble_kernels
      Array.new(size) do |kernel_index|
        disassemble_kernel kernel_index
      end
    end

    private def io_registers(input)
      reg_enum_type = Libevoasm.enum_type(:x64_reg_id)
      reg_enum_type.to_h.each_with_object([]) do |(k, v), acc|
        unless k == :none
          io =
            if input
              Libevoasm.kernel_is_input_reg(self, v)
            else
              Libevoasm.kernel_is_output_reg(self, v)
            end

          acc << k if io
        end
      end
    end

    # Gives the input registers of this kernel
    # @return [Array<Symbol>] input registers
    def input_registers
      io_registers true
    end

    # Gives the output registers of this kernel
    # @return [Array<Symbol>] output registers
    def output_registers
      reg_enum_type = Libevoasm.enum_type(:x64_reg_id)
      Array.new(Libevoasm.kernel_get_arity self) do |index|
        reg_enum_type[Libevoasm.kernel_get_output_reg(self, index)]
      end
    end

    private def format_disassembly(disasm)
      disasm.map do |line|
        "0x#{line[0].to_s 16}:\t#{line[1]}\t#{line[2]}"
      end.join("\n")
    end

    # Disassembles the whole kernel
    # @param frame [Bool] whether to include the stack frame and
    # @param format [Bool] whether to format the assembly
    # @return [String, Array<String>] the formatted assembly as string
    #   if format is set, an array of address, opcode, operands triples otherwise.
    def disassemble(frame = false, format: false)
      code_ptr_ptr = FFI::MemoryPointer.new :pointer
      code_len = Libevoasm.kernel_get_code self, frame, code_ptr_ptr
      code_ptr = code_ptr_ptr.read_pointer
      code = code_ptr.read_string(code_len)

      disasm = X64.disassemble code, code_ptr.address

      if format
        format_disassembly disasm
      else
        disasm
      end
    end
  end
end
