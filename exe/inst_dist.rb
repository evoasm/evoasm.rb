begin
  require 'evoasm'
  require 'evoasm/x64'
  require 'evoasm/x64/cpu_state'
rescue LoadError
  $LOAD_PATH.unshift '../lib'
end

instructions = Evoasm::X64::instruction_names(:gp, :rflags, :xmm).map do |name|
  Evoasm::X64.instruction name
end


buffer = Evoasm::Buffer.new 1024, :mmap

def run(buffer, instruction, parameters, cpu_state)
  buffer.reset
  Evoasm::X64.emit_stack_frame buffer do
    instruction.encode parameters, buffer, basic: true
    cpu_state.emit_store buffer
  end

  begin
    buffer.execute!
  rescue ExceptionError
  end
end

dists = Hash.new { |h, k| h[k] = {} }
min_dist = Float::INFINITY
max_dist = 0

COLORS = [[0, 0, 0], [0,0,1], [0,1,0], [1,1,0], [1,0,0], [1, 1, 1]].freeze

def heat_color(dist, min_dist, max_dist)
  normalized_dist = (dist - min_dist) / (max_dist - min_dist)

  distance = (normalized_dist * COLORS.size - 1)
  floor_distance = distance.to_i
  floor_color = COLORS[floor_distance]
  ceil_color = COLORS[floor_distance + 1]
  relative_distance = distance - floor_distance

  heat_color = Array.new(3) do |color_index|
    floor_distance[color_index] + relative_distance * (ceil_color[color_index] - floor_color[color_index])
  end

  heat_color.map! do |color|
    (color * 255).to_i
  end

  "#%x%x%x".%(*color)
end

instructions.each do |instruction|

  instructions.each do |other_instruction|

    100.times do
      parameters = Evoasm::X64::Parameters.random instruction
      other_parameters = Evoasm::X64::Parameters.random other_instruction

      cpu_state = Evoasm::X64::CPUState.random
      other_cpu_state = cpu_state.clone

      run buffer, instruction, parameters, cpu_state
      run buffer, other_instruction, other_parameters, other_cpu_state

      dist = cpu_state.distance(other_cpu_state, :absdiff)
      dist += cpu_state.distance(other_cpu_state, :xor)

      min_dist = dist if min_dist > dist
      max_dist = dist if max_dist < dist

      dists[instruction.name][other_instruction.name] = dist
    end
  end
end
