require 'ffi'

module Evoasm

  # Represents a program comprising one ore multiple kernels
  class Program < FFI::AutoPointer

    require_relative 'program/io.rb'

    private_class_method :new

    def self.wrap(ptr)
      new ptr
    end

    # @!visibility private
    def self.release(ptr)
      Libevoasm.program_destroy(ptr)
      Libevoasm.program_free(ptr)
    end

    # Runs the program with the given input
    # @param input_tuple [Array] an input tuple
    # @return [Array] the output tuple corresponding to the given input
    def run(*input_tuple)
      run_all(input_tuple).first
    end

    # Like {#run}, but runs multiple input tuples at once
    # @param input_examples [Array] an array of input tuples
    # @return [Array] an array of output tuples
    def run_all(*input_examples)
      input = Program::Input.new(input_examples)

      output_ptr = Libevoasm.program_run self, input

      if output_ptr.null?
        raise Error.last
      end

      Program::Output.new(output_ptr).to_a
    end

    # Gives the size of the program as the number of kernels
    # @return [Integer] size
    def size
      Libevoasm.program_get_size self
    end

    # Eliminates intron instructions (instructions without effect)
    # @return [Program] a new program with introns eliminated
    def eliminate_introns
      program = Libevoasm.program_alloc
      unless Libevoasm.program_elim_introns self, program
        raise Error.last
      end

      self.class.wrap program
    end

    # Gives the disassembly for the specified kernel
    # @param kernel_index [Integer] index of kernel to disassemble
    # @return [String] disassembly
    def disassemble_kernel(kernel_index)
      code_ptr_ptr = FFI::MemoryPointer.new :pointer
      code_len = Libevoasm.program_get_kernel_code self, kernel_index, code_ptr_ptr
      code_ptr = code_ptr_ptr.read_pointer
      code = code_ptr.read_string(code_len)

      X64.disassemble code, code_ptr.address
    end

    # Gives the disassembly for all kernels in the program
    # @return [Array<String>] array of disassembly
    def disassemble_kernels
      Array.new(size) do |kernel_index|
        disassemble_kernel kernel_index
      end
    end

    private def io_registers(input, kernel_index)
      reg_enum_type = Libevoasm.enum_type(:x64_reg_id)
      reg_enum_type.to_h.each_with_object([]) do |(k, v), acc|
        unless k == :none
          io =
            if input
              Libevoasm.program_is_kernel_input_reg(self, kernel_index, v)
            else
              Libevoasm.program_is_kernel_output_reg(self, kernel_index, v)
            end

          acc << k if io
        end
      end
    end

    # Gives the input registers of the specified kernel
    # @param kernel_index [Integer]
    # @return [Array<Symbol>] input registers
    def kernel_input_registers(kernel_index = 0)
      io_registers true, kernel_index
    end

    # Gives the size of the specified kernel
    # @param kernel_index [Integer]
    # @return [Integer] kernel size in number of instructions
    def kernel_size(kernel_index = 0)
      Libevoasm.program_get_kernel_size self, kernel_index
    end

    # Gives the output registers of the specified kernel
    # @param kernel_index [Integer]
    # @return [Array<Symbol>] output registers
    def kernel_output_registers(kernel_index = size - 1)
      io_registers false, kernel_index
    end

    def output_registers
      reg_enum_type = Libevoasm.enum_type(:x64_reg_id)
      Array.new(Libevoasm.program_get_arity self) do |index|
        reg_enum_type[Libevoasm.program_get_output_reg(self, index)]
      end
    end

    private def format_disassembly(disasm)
      disasm.map do |line|
        "0x#{line[0].to_s 16}:\t#{line[1]}\t#{line[2]}"
      end.join("\n")
    end

    # Disassembles the whole program
    # @param frame [Bool] whether to include the stack frame and
    # @param format [Bool] whether to format the assembly
    # @return [String, Array<String>] the formatted assembly as string
    #   if format is set, an array of address, opcode, operands triples otherwise.
    def disassemble(frame = false, format: false)
      code_ptr_ptr = FFI::MemoryPointer.new :pointer
      code_len = Libevoasm.program_get_code self, frame, code_ptr_ptr
      code_ptr = code_ptr_ptr.read_pointer
      code = code_ptr.read_string(code_len)

      disasm = X64.disassemble code, code_ptr.address

      if format
        format_disassembly disasm
      else
        disasm
      end
    end

    # Visualizes the program and its kernels using Graphviz
    # @return [GV::Graph]
    def to_gv
      require 'gv'

      graph = GV::Graph.open 'g'

      graph[:labelloc] = 't'
      graph[:label] = output_registers.join(', ')

      disasms = disassemble_kernels
      addrs = disasms.map do |disasm|
        disasm.first&.first
      end

      arch_info = Libevoasm.get_arch_info Libevoasm.get_current_arch
      condition_count = Libevoasm.arch_info_get_n_conds arch_info
      jmp_cond_enum_type = Libevoasm.enum_type :x64_jmp_cond

      size.times do |kernel_index|
        label = '<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0">'

        label << '<TR>'
        label << %Q{<TD COLSPAN="3"><B>Kernel #{kernel_index}</B> #{kernel_size kernel_index} (#{kernel_input_registers(kernel_index).join ', '})</TD>}
        label << '</TR>'

        disasm = disasms[kernel_index]
        addr = addrs[kernel_index]
        jmp_addrs = []

        disasm.each do |line|
          op_str = line[2]

          label << '<TR>'
          label << %Q{<TD ALIGN="LEFT">0x#{line[0].to_s 16}</TD>}
          label << %Q{<TD ALIGN="LEFT">#{line[1]}</TD>}

          if op_str =~ /0x(\h+)/
            jmp_addr = Integer($1, 16)
            jmp_addrs << jmp_addr
            port = jmp_addr
          else
            port = ''
          end
          label << %Q{<TD ALIGN="LEFT" PORT="#{port}">#{op_str}</TD>}
          label << '</TR>'
        end

        label << '<TR>'
        label << %Q{<TD COLSPAN="3">(#{kernel_output_registers(kernel_index).join ', '})</TD>}
        label << '</TR>'
        label << '</TABLE>'

        node = graph.node addr.to_s,
                          shape: :none,
                          label: graph.html(label)


        successors = Array.new(condition_count) do |condition_index|
          [
            Libevoasm.program_get_succ_kernel_idx(self, kernel_index, condition_index),
           jmp_cond_enum_type[condition_index]
          ]
        end.select {|succ_kernel_index, _| succ_kernel_index != -1 }

        p successors

        successors.each do |successor, condition|
          succ_addr = addrs[successor]
          tail_port = succ_addr.to_s
            # if jmp_addrs.include? succ_addr
            #   # Remove, in case we have the same
            #   # successor multiple times
            #   # only one of which goes through the jump
            #   jmp_addrs.delete succ_addr
            # else
            #   's'
            # end
          graph.edge 'e', node, graph.node(succ_addr.to_s), tailport: tail_port, headport: 'n', label: condition
        end
      end

      graph
    end
  end
end
