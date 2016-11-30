require 'evoasm'
require 'evoasm/x64'

buffer = Evoasm::Buffer.new 1024
Evoasm::X64.emit_stack_frame buffer do
  Evoasm::X64.encode(:mov_rm32_imm32, {reg0: :a, imm0: 1}, buffer)
  Evoasm::X64.encode(:mov_rm32_imm32, {reg0: :b, imm0: 2}, buffer)
  Evoasm::X64.encode(:add_r32_rm32, {reg0: :a, reg1: :b}, buffer)
end

puts "Result: #{buffer.execute!}"

buffer.reset

Evoasm::X64.emit_stack_frame buffer do
  Evoasm::X64.encode(:mov_rm32_imm32, {reg0: :b, imm0: 0}, buffer)
  Evoasm::X64.encode(:mov_rm32_imm32, {reg0: :a, imm0: 100}, buffer)
  Evoasm::X64.encode(:div_rm64, {reg0: :b}, buffer)
end

begin
  buffer.execute!
rescue Evoasm::ExceptionError => e
  puts "Execution failed with exception `#{e.exception_name}'"
end



