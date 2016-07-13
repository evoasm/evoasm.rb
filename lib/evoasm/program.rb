require 'evoasm/search'

module Evoasm
  class Program
    include Search::Util

    def run(*input_example)
      run_all(input_example).first
    end

    def run_all(*input_examples)
      input_examples, input_arity = flatten_examples input_examples
      __run__ input_examples, input_arity
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
