require 'evoasm'
require 'evoasm/x64'

require 'colorize'

Evoasm.log_level = :info

expression = ARGV[0]

module ExpressionScope
  extend Math
end

p expression

examples = (0..10).map do |x|
  [x, ExpressionScope.module_eval(expression)]
end.to_h


instructions = Evoasm::X64.instruction_names(:xmm)

instructions += %i(
  mov_r8_imm8
  mov_r16_imm16
  mov_r32_imm32
  mov_rm8_imm8
  mov_rm16_imm16
  mov_rm32_imm32
  mov_rm64_imm32
)

p instructions.grep(/aes/)
p instructions.grep(/pins/)

parameters = Evoasm::Population::Parameters.new do |p|
  p.instructions = instructions
  p.examples = examples
  p.deme_size = 1024
  p.deme_count = 6
  p.kernel_size = 10
  p.distance_metric = :absdiff
  p.parameters = %i(reg0 reg1 reg2 reg3 imm0)

  regs = %i(xmm0 xmm1 xmm2 xmm3 a b c d)

  p.domains = {
    reg0: regs,
    reg1: regs,
    reg2: regs,
    reg3: regs,
    imm0: [2.0]
  }
end

puts "Supported features:"
Evoasm::X64.features.each do |feature, supported|
  puts "\t#{feature.to_s.upcase}: #{supported ? 'YES' : 'NO'}"
end
puts

population = Evoasm::Population.new parameters
kernel, loss = population.run loss: 0.0, max_generations: 100000 do
  population.report
end

puts kernel.disassemble format: true

puts

kernel = kernel.eliminate_introns
puts kernel.disassemble format: true

puts "Inputs registers: #{kernel.input_registers.join(', ').bold}"
puts "Average loss is #{loss.to_s.bold}"
puts
puts "x\texpected\tactual"
examples.each do |x, y|
  puts "#{x}\t#{y.round(3)}\t\t#{kernel.run(x).round(3)}"
end