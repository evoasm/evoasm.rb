require 'evoasm/search'

module Evoasm
  class ADF < FFI::AutoPointer

    def initialize(other_ptr)
      ptr = Libevoasm.adf_alloc
      unless Libevoasm.adf_clone other_ptr, ptr
        Libevoasm.adf_free(ptr)
        raise Libevoasm::Error.last
      end
      super ptr
    end

    def self.release(ptr)
      Libevoasm.adf_destroy(ptr)
      Libevoasm.adf_free(ptr)
    end

    def run(*input_example)
      run_all(input_example).first
    end

    def run_all(*input_examples)
      input = Libevoasm::ADFInput.new(input_examples)
      output = Libevoasm::ADFOutput.new
      unless Libevoasm.adf_run self, input, output
        raise Libevoasm::Error.last
      end
      output_ary = output.to_a

      Libevoasm.adf_io_destroy output

      output_ary
    end

    def to_gv
      require 'gv'

      graph = GV::Graph.open 'g'

      disasms = []
      addrs = []

      self.kernels.each do |kernel|
        disasm = kernel.disassemble
        disasms[kernel.index] = disasm
        addrs[kernel.index] = disasm.first.first
      end

      self.kernels.each do |kernel|
        label = '<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0">'

        label << '<TR>'
        label << %Q{<TD COLSPAN="3"><B>Kernel #{kernel.index}</B></TD>}
        label << '</TR>'

        disasm = disasms[kernel.index]
        addr = addrs[kernel.index]
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
        label << '</TABLE>'

        node = graph.node addr.to_s,
                          shape: :none,
                          label: graph.html(label)

        kernel.successors.each do |successor|
          succ_addr = addrs[successor.index]
          tail_port =
            if jmp_addrs.include? succ_addr
              # Remove, in case we the same
              # successor multiple times
              # only one of which goes through the jump
              jmp_addrs.delete succ_addr
              succ_addr.to_s
            else
              's'
            end
          graph.edge 'e', node, graph.node(succ_addr.to_s), tailport: tail_port, headport: 'n'
        end
      end

      graph
    end
  end
end
