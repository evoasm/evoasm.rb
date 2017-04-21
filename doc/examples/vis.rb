require 'evoasm'
require 'evoasm/x64'

Evoasm.log_level = :warn

examples = {
  [5, 1] => 1,
  [15, 5] => 5,
  [8, 2] => 2,
  [8, 4] => 4,
  [8, 6] => 2,
  [16, 8] => 8,
  [16, 2] => 2,
  [100, 10] => 10,
  [60, 10] => 10
}

parameters = Evoasm::Population::Parameters.new do |p|
  p.instructions = Evoasm::X64.instruction_names(:gp, :rflags)
  p.examples = examples
  p.deme_size = 2048
  p.parameters = %i(reg0 reg1 reg2 reg3)
  p.kernel_size = 20
  p.deme_count = 2
end

population = Evoasm::Population.new parameters
kernel, loss = population.run do
  p "gen"
  population.plot File.join(__dir__, 'loss.gif')
end

p loss

