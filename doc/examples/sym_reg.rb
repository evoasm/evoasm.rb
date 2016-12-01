require 'evoasm'
require 'evoasm/x64'

Evoasm.log_level = :warn

examples = {
  0.0 => 0.0,
  0.5 => 1.0606601717798212,
  1.0 => 1.7320508075688772,
  1.5 => 2.5248762345905194,
  2.0 => 3.4641016151377544,
  2.5 => 4.541475531146237,
  3.0 => 5.744562646538029,
  3.5 => 7.0622234459127675,
  4.0 => 8.48528137423857,
  4.5 => 10.00624804809475,
  5.0 => 11.61895003862225
}

parameters = Evoasm::Population::Parameters.new do |p|
  p.instructions = Evoasm::X64.instruction_names(:xmm).grep /(add|mul|sqrt).*?sd/
  p.examples = examples
  p.deme_size = 1024
  p.deme_count = 1
  p.kernel_size = 10
  p.program_size = 1
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
program, loss = population.run

puts program.disassemble format: true

puts

puts program.run 6.0
puts program.run 7.0

puts

program = program.eliminate_introns
puts program.disassemble format: true

puts

puts program.run 6.0
puts program.run 7.0

