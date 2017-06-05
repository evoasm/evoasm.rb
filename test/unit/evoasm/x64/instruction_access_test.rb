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

      def accessed_operand(register, instruction, parameters, mode)
        instruction.operands.find do |operand|
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
        end
      end

      def accessed_registers(registers, instruction, parameters, mode, only_registers: false, include_operand_index: false, word_mask: false)
        registers.map do |register|
          operand = accessed_operand register, instruction, parameters, mode

          if operand
            word = operand.word(mode, parameters)

            if word
              if only_registers
                register
              else
                tuple = [register]
                if word_mask
                  tuple << operand.word_mask(mode, parameters)
                else
                  tuple << word
                end

                if include_operand_index
                  tuple << operand_index
                end

                tuple
              end
            end
          end
        end.compact
      end

      def self.define_write_test(instruction)
        define_method :"test_#{instruction.name}_writes" do
          buffer = Evoasm::Buffer.new 1024, :mmap

          100.times do
            parameters = Evoasm::X64::Parameters.random instruction

            catch :invalid_params do
              cpu_state_before = CPUState.new
              cpu_state_after = CPUState.new

              buffer.reset
              X64.emit_stack_frame buffer do
                cpu_state_before.emit_store buffer
                begin
                  instruction.encode parameters, buffer
                rescue Error
                  throw :invalid_params
                end
                cpu_state_after.emit_store buffer
              end

              begin
                buffer.execute!

                cpu_state_diff = cpu_state_before.xor cpu_state_after

                written_registers = cpu_state_diff.to_h.select do |register, value|
                  # Ignore for now
                  # MXCSR is almost never checked
                  # and does not really affect code flow
                  register != :mxcsr && !value.all? {|v| v == 0}
                end.map(&:first)

                expected_written_registers = accessed_registers(written_registers, instruction, parameters, :write, only_registers: true)
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
      end

      EXPECTED_MASK = [0, 0, 0, 0, 0, 0, 0, 0]
      def self.define_partial_write_test(instruction)
        define_method :"test_#{instruction.name}_partial_writes" do
          buffer = Evoasm::Buffer.new 1024, :mmap

          masks = instruction.operands.map do |operand|
            next nil if operand.register_type == :rflags || operand.register_type == :mxcsr
            operand.word_mask(:write).tap do |mask|
              p [operand, mask]
            end
          end

          p [instruction.name, masks.map {|mask| Array(mask).map{|m| m.to_s 2}}]

          500.times do

            parameters = Evoasm::X64::Parameters.random instruction
            parameters[:reg0_high_byte?] = false
            parameters[:reg1_high_byte?] = false

            catch :invalid_params do
              cpu_state_before = CPUState.random
              cpu_state_after = cpu_state_before.clone #CPUState.new

              buffer.reset
              X64.emit_stack_frame buffer do
                cpu_state_before.emit_load buffer
                begin
                  instruction.encode parameters, buffer
                rescue Error
                  throw :invalid_params
                end
                cpu_state_after.emit_store buffer
              end

              begin
                buffer.execute!

                cpu_state_diff = cpu_state_before.xor cpu_state_after

                writes = cpu_state_diff.to_h

                #expected_written_registers = accessed_registers(written_registers, instruction, parameters, :write, include_operand_index: true, word_mask: true)

                writes.each do |register, values|
                  next if register == :ip || register == :rflags || register == :mxcsr
                  next if values.all? {|v| v == 0}

                  operand = accessed_operand register, instruction, parameters, :write
                  if operand.nil?
                    p ["?", register, parameters, values]
                  end
                  p ["write", instruction.name, register, values.map { |v| v.to_s(2) }, operand.index]
                  mask_for_operand = masks[operand.index]
                  values.each_with_index do |value, value_index|
                      mask_for_operand[value_index] &= ~value
                  end
                end

                  # p expected_written_registers
                  # p accessed_registers(written_registers, instruction, parameters, :write)

                  # unexpected_written_registers = written_registers - expected_written_registers
                  #
                  # assert_empty unexpected_written_registers, "No operand found that writes to #{unexpected_written_registers} ("\
                  #        "(#{instruction.name} #{parameters.inspect})."\
                  #        "The following registers have been written to #{written_registers}"
                  #
                  #   #buffer.__log__ :warn
              rescue ExceptionError
              end
            end
          end

          masks.each_with_index do |mask, mask_index|
            if mask
              operand = instruction.operand mask_index
              mask.each_with_index do |mask_value, mask_value_index|
                mask_bin_str = mask_value.to_s(2).ljust(64, '0')
                mask_bin_str_reverse = mask_bin_str.reverse
                4.times do |word_index|
                  word = mask_bin_str_reverse[word_index * 4, 16]
                  unwritten_bits_count = word.each_char.count { |char| char == '0' }

                  refute unwritten_bits_count == 0, "#{mask_value_index * 4 + word_index}th word has no writes on operand #{operand.inspect} (#{mask_bin_str.each_char.each_slice(16).map(&:join).join(' ')})"
                end
              end
            end
          end
          p [instruction.name, masks]
        end

      end

      def self.define_read_test(instruction)
        define_method :"test_#{instruction.name}_reads" do
          buffer = Evoasm::Buffer.new 1024, :mmap

          20.times do
            parameters = Evoasm::X64::Parameters.random instruction

            catch(:invalid_params) do
              cpu_state_before = CPUState.new
              read_registers = accessed_registers(X64.registers, instruction, parameters, :read)
              read_registers.each do |read_register, _|
                cpu_state_before[read_register] = Array.new(4) {rand(999999999)}
              end
              #p [instruction.name, accessed_registers(X64.registers, instruction, parameters, :read)]

              non_read_registers = X64.registers - accessed_registers(X64.registers, instruction, parameters, :read, only_registers: true)
              written_registers = accessed_registers(X64.registers, instruction, parameters, :write)
              expected_cpu_state_after = nil

              20.times do
                non_read_registers.each do |non_read_register|
                  value = Array.new(4) {rand(999999999)}
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
                  begin
                    instruction.encode parameters, buffer
                  rescue Error
                    throw :invalid_params
                  end
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
      end


      X64.instruction_names(:rflags, :mxcsr, :gp, :mm, :xmm, :zmm).each do |instruction_name|
        instruction = Evoasm::X64.instruction instruction_name
        next unless instruction.basic?
        next if instruction.name == :std

        define_write_test instruction
        define_partial_write_test instruction

        next if instruction.name =~ /^cmov/
        #next if instruction.name =~ /^pins/
        define_read_test instruction
      end
    end
  end
end
