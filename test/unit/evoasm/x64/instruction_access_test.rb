require 'evoasm/test'
require 'evoasm/buffer'
require 'evoasm/x64'
require 'evoasm/x64/cpu_state'

require 'x64_helper'

module Evoasm
  module X64
    class InstructionAccessTest < Minitest::Test
      include X64Helper

      def setup
        super
      end

      def self.test_order
        :alpha
      end

      PARAMETERS = %i(reg0 reg1 reg2 reg3 imm0)

      X64.instruction_names(:rflags, :mxcsr, :gp, :mm, :xmm, :zmm).each do |instruction_name|
        instruction = Evoasm::X64.instruction instruction_name
        next unless instruction.basic?

        define_method :"test_#{instruction_name}" do
          parameters = Evoasm::X64::Parameters.new(basic: true)
          buffer = Evoasm::Buffer.new :mmap, 1024

          instruction.parameters.each do |parameter|
            if PARAMETERS.include? parameter.name
              parameter_value = parameter.domain.rand

              if parameter.name.to_s =~ /div/
                parameter_value = 0
              end
              parameters[parameter.name] = parameter_value

            end
          end

          cpu_state_before = CPUState.new
          cpu_state_after = CPUState.new

          X64.emit_stack_frame buffer do
            cpu_state_before.emit_store buffer
            instruction.encode parameters, buffer, basic: true
            cpu_state_after.emit_store buffer
          end

          begin
            buffer.execute!

            #raise caught_exception if caught_exception

            cpu_state_diff = cpu_state_before.xor cpu_state_after
            #          cpu_state_diff.set :xmm0, 1
            written_registers = cpu_state_diff.to_h.select do |register, value|
              # Ignore for now
              # MXCSR is almost never checked
              # and does not really affect code flow
              register != :mxcsr && !value.all? { |v| v == 0 }
            end.map(&:first)

            written_registers.each do |register|
              next if register == :mxcsr
              operands = instruction.operands.select do |operand|
                next false unless operand.written?
                next true if operand.register == register

                parameter_name = operand.parameter&.name
                next false if parameter_name.nil?
                parameters[parameter_name] == register

              end.to_a

              buffer.__log__ :warn
              refute operands.empty?,
                     "No operand found that writes to #{register} (#{cpu_state_before.get register}"\
                     " -> #{cpu_state_after.get register}), (#{instruction_name} #{parameters.inspect})."\
                     "The following registers have been written to #{written_registers}"
            end
          rescue ExceptionError
          end
        end
      end
    end
  end
end