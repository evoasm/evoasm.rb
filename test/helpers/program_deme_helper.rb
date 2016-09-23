require 'evoasm'
require 'evoasm/x64'

module ProgramDemeHelper

  def set_deme_parameters_ivars
    @examples = {
      1 => 2,
      2 => 3,
      3 => 4
    }
    @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
    @kernel_size = (1..15)
    @kernel_count = 1
    @size = 1600
    @parameters = %i(reg0 reg1 reg2 reg3)
  end

  def new_deme
    Evoasm::ProgramDeme.new :x64 do |p|
      p.instructions = @instruction_names
      p.kernel_size = @kernel_size
      p.kernel_count = @kernel_count
      p.size = @size
      p.parameters = @parameters
      p.examples = @examples
    end
  end
end
