require 'evoasm'
require 'evoasm/x64'

count_1s = {
  0b0 => 0,
  0b1 => 1,
  0b100 => 1,
  0b101 => 2,
  0b111 => 3,
  0b1000 => 1
}

parameters = Evoasm::Population::Parameters.new do |p|
  p.instructions = Evoasm::X64.instruction_names(:gp, :rflags)
  p.deme_size = 1024
  p.deme_count = 1
  p.kernel_size = 1
  p.topology_size = 1
  p.parameters = %i(reg0 reg1 reg2 reg3)
end

parameters.examples = count_1s

population = Evoasm::Population.new parameters
program, loss = population.run

puts "#{program.disassemble.first[1]}"

puts

count_trailing_0s = {
  0b100 => 2,
  0b1 => 0,
  0b10 => 1,
  0b101 => 0,
  0b10000 => 4
}

parameters.examples = count_trailing_0s

population = Evoasm::Population.new parameters
program, loss = population.run

puts "#{program.disassemble.first[1]}"
