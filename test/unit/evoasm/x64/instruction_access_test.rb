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

      def random_parameters(instruction)
        parameters = Evoasm::X64::Parameters.new(basic: true)
        instruction.parameters.each do |parameter|
          if PARAMETERS.include? parameter.name
            parameter_value = parameter.domain.rand
            parameters[parameter.name] = parameter_value
          end
        end

        parameters
      end

      def accessed_registers(registers, instruction, parameters, mode)
        registers.map do |register|
          word = instruction.operands.find do |operand|
            case mode
            when :write
              next false unless operand.written? || operand.maybe_written?
            when :read
              next false unless operand.read?
            else
              raise
            end

            next true if operand.register == register

            parameter_name = operand.parameter&.name
            next false if parameter_name.nil?
            parameters[parameter_name] == register
          end&.word

          [register, word] if word
        end.compact.to_h
      end

      def self.define_write_test(instruction)
        define_method :"test_#{instruction.name}_writes" do
          buffer = Evoasm::Buffer.new 1024, :mmap

          100.times do
            parameters = random_parameters(instruction)

            cpu_state_before = CPUState.new
            cpu_state_after = CPUState.new

            buffer.reset
            X64.emit_stack_frame buffer do
              cpu_state_before.emit_store buffer
              instruction.encode parameters, buffer, basic: true
              cpu_state_after.emit_store buffer
            end

            begin
              buffer.execute!

              cpu_state_diff = cpu_state_before.xor cpu_state_after

              written_registers = cpu_state_diff.to_h.select do |register, value|
                # Ignore for now
                # MXCSR is almost never checked
                # and does not really affect code flow
                register != :mxcsr && !value.all? { |v| v == 0 }
              end.map(&:first)

              expected_written_registers = accessed_registers(written_registers, instruction, parameters, :write).keys
              unexpected_written_registers = written_registers - expected_written_registers

              assert_empty unexpected_written_registers, "No operand found that writes to #{unexpected_written_registers} ("\
                       "(#{instruction.name} #{parameters.inspect})."\
                       "The following registers have been written to #{written_registers}"

                #buffer.__log__ :warn
            rescue ExceptionError
            end
          end
        end
      end

      def self.define_read_test(instruction)
        define_method :"test_#{instruction.name}_reads" do
          buffer = Evoasm::Buffer.new 1024, :mmap

          20.times do
            parameters = random_parameters(instruction)

            cpu_state_before = CPUState.new
            read_registers = accessed_registers(X64.registers, instruction, parameters, :read)
            read_registers.each do |read_register, _|
              cpu_state_before[read_register] = Array.new(4) { rand(999999999) }
            end
            #p [instruction.name, accessed_registers(X64.registers, instruction, parameters, :read)]

            non_read_registers = X64.registers - accessed_registers(X64.registers, instruction, parameters, :read).keys
            written_registers = accessed_registers(X64.registers, instruction, parameters, :write)
            expected_cpu_state_after = nil

            20.times do
              non_read_registers.each do |non_read_register|
                value = Array.new(4) { rand(999999999) }
                #next if non_read_register == :rflags
                #p [non_read_register, value]
                cpu_state_before[non_read_register] = value
              end
              #parameters = random_parameters(instruction)

              #p cpu_state_before.get :rflags

              buffer.reset

              cpu_state_after = CPUState.new
              X64.emit_stack_frame buffer do
                cpu_state_before.emit_load buffer
                instruction.encode parameters, buffer, basic: true
                cpu_state_after.emit_store buffer
              end

              begin
                #buffer.__log__ :warn
                buffer.execute!

                if expected_cpu_state_after
                  written_registers.each do |written_register, written_word|
                    next if written_register == :rflags
                    message = "#{written_register} mismatch (#{cpu_state_before[written_register]})"\
                              "#{non_read_registers}"
                    #p [instruction.name, parameters, cpu_state_after.to_h]
                    assert_equal expected_cpu_state_after[written_register, written_word], cpu_state_after[written_register, written_word], message
                  end
                else
                  #p ["pre", instruction.name, parameters, cpu_state_after.to_h]
                  expected_cpu_state_after = cpu_state_after
                end

              rescue ExceptionError
              end
            end
          end
        end
      end


      X64.instruction_names(:rflags, :mxcsr, :gp, :mm, :xmm, :zmm).each do |instruction_name|
        instruction = Evoasm::X64.instruction instruction_name
        next unless instruction.basic?
        next if instruction.name == :std

        define_write_test instruction

        next if instruction.name =~ /^cmov/
        #next if instruction.name =~ /^pins/
        define_read_test instruction
      end
    end
  end
end
