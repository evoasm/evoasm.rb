require 'evoasm'
require 'evoasm/x64'

Evoasm.log_level = :info

expression = ARGV[0]

module ExpressionScope
  extend Math
end

p expression

examples = (0..100).step(0.5).map do |x|
  [x, ExpressionScope.module_eval(expression)]
end.to_h

parameters = Evoasm::Population::Parameters.new do |p|
  p.instructions = Evoasm::X64.instruction_names(:xmm)
  p.examples = examples
  p.deme_size = 1024
  p.deme_count = 1
  p.kernel_size = 10
  p.distance_metric = :absdiff
  p.parameters = %i(reg0 reg1 reg2 reg3)

  regs = %i(xmm0 xmm1 xmm2 xmm3)

  p.domains = {
    reg0: regs,
    reg1: regs,
    reg2: regs,
    reg3: regs
  }
end

puts "Supported features:"
Evoasm::X64.features.each do |feature, supported|
  puts "\t#{feature.to_s.upcase}: #{supported ? 'YES' : 'NO'}"
end
puts

population = Evoasm::Population.new parameters
kernel, loss = population.run do
  population.report
end

puts kernel.disassemble format: true

puts

kernel = kernel.eliminate_introns
puts kernel.disassemble format: true

