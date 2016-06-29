require 'yaml'
require 'pastel'
require 'pry'

module Evoasm
  module Cli
    class Search
      attr_reader :filename

      def initialize(filename, options)
        @filename = filename
        raise ArgumentError, 'filename is nil' if filename.nil?

        if options.any?{|o| o =~ /\--log-level=(\d)/}
          Evoasm.log_level = $1.to_i
        end
      end

      def start!
        x64 = X64.new
        params = YAML.load(File.read filename)
        insts = filter_insts x64.instructions, params['instructions']

        p insts.map(&:name)
        pastel = Pastel.new

        program_size = parse_range params['program_size']
        kernel_size = parse_range params['kernel_size']
        program_counter = 0
        max_programs = params['max_programs']

        domains = convert_domains_hash params['domains']
        parameters = (params['parameters'] || %i(reg0 reg1 reg2 imm0 imm1)).map(&:to_sym)

        start_ts = Time.now

        search = Evoasm::Search.new x64,
                   examples: params['examples'],
                   instructions: insts,
                   kernel_size: kernel_size,
                   program_size: program_size,
                   population_size: params['population_size'],
                   parameters: parameters,
                   domains: domains

        search.start!(params['min_fitness'] || 0.0) do |program, fitness|
          ts = Time.now
          puts pastel.bold "Program #{program_counter}, #{ts.strftime '%H:%M:%S'} (found after #{(ts - start_ts).to_i} seconds)"

          if program.buffer.respond_to? :disassemble
            puts program.buffer.disassemble.join "\n"
          else
            puts program.instructions.map(&:name)
          end

          puts

          if params['console'] != false
            binding.pry
          end

          program_counter += 1

          if program_counter == max_programs
            # stops search
            return false
          end
        end
      end

      private
      def filter_insts(insts, params)
        op_types = %i(rm reg imm)
        reg_types = %i(rflags)
        bad_regs = %i(SP IP)

        grep_regexp = params && Regexp.new(params['grep']) rescue nil
        grep_v_regexp = params && Regexp.new(params['grep_v']) rescue nil

        reg_types.concat params['reg_types'].map(&:to_sym)

        insts.select do |inst|
          next false if grep_regexp && inst.name !~ grep_regexp
          next false if grep_v_regexp && inst.name =~ grep_v_regexp
          next false if inst.operands.size == 0

          inst.operands.all? do |op|
            next false unless op_types.include? op.type
            if op.register
              next false unless reg_types.include?(op.register.type)
              next false if bad_regs.include? op.register.name
            end

            true
          end
        end
      end

      def convert_domains_hash(hash)
        Hash(hash).map do |k, v|
          new_k = k.to_sym
          new_v =
            case v
            when Array
              v.map {|e| e.is_a?(String) ? e.to_sym : e }
            else
              v
            end
          [new_k, new_v]
        end.to_h
      end

      def parse_range(str)
        case str
        when Integer
          str
        when /^\(?(\d+)\.\.(\.?)(\d+)\)?$/
          Range.new($1.to_i, $3.to_i, !$2.empty?)
        else
          raise ArgumentError, "invalid range '#{str}'"
        end
      end
    end
  end
end
