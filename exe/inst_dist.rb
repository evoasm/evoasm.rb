begin
  require 'evoasm'
  require 'evoasm/x64'
  require 'evoasm/x64/cpu_state'
rescue LoadError
  $LOAD_PATH.unshift '../lib'
end

require 'yaml'

instructions = Evoasm::X64::instruction_names(:gp, :rflags, :xmm)[0..200].map do |name|
  Evoasm::X64.instruction name
end


buffer = Evoasm::Buffer.new 1024, :mmap

def run(buffer, instruction, parameters, cpu_state)
  buffer.reset
  Evoasm::X64.emit_stack_frame buffer do
    cpu_state.emit_load buffer
    instruction.encode parameters, buffer, basic: true
    cpu_state.emit_store buffer
  end

  begin
    buffer.execute!
  rescue Evoasm::ExceptionError
  end
end

dists = Array.new(instructions.size) {Array.new(instructions.size, 0)}
min_dist = Float::INFINITY
max_dist = 0

COLORS = [[1, 1, 1], [1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 0, 1], [0, 0, 0]].freeze

def heat_color(dist, min_dist, max_dist)
  return "pink" if dist.nil?

  normalized_dist = (dist - min_dist) / (max_dist - min_dist)

  distance = normalized_dist * (COLORS.size - 2)
  floor_distance = distance.to_i
  floor_color = COLORS[floor_distance]
  ceil_color = COLORS[floor_distance + 1]
  relative_distance = distance - floor_distance

  heat_color = Array.new(3) do |color_index|
    floor_color[color_index] + relative_distance * (ceil_color[color_index] - floor_color[color_index])
  end

  heat_color.map! do |color|
    (color * 255).to_i
  end

  "#%02x%02x%02x".%(heat_color)
end

instructions.each_with_index do |instruction, index|

  instructions.each_with_index do |other_instruction, other_index|

    50.times do
      parameters = Evoasm::X64::Parameters.random instruction

      cpu_state = Evoasm::X64::CPUState.random
      other_cpu_state = cpu_state.clone

      begin
        run buffer, instruction, parameters, cpu_state
        run buffer, other_instruction, parameters, other_cpu_state


        dist = cpu_state.distance(other_cpu_state, :absdiff)
        dist += cpu_state.distance(other_cpu_state, :xor)

        min_dist = dist if min_dist > dist
        max_dist = dist if max_dist < dist

        if instruction.name == other_instruction.name
          puts dist
          raise "#{dist}" unless dist == 0
        end

        dists[index][other_index] = dist
      rescue Evoasm::Error
        dists[index][other_index] = nil
      end

    end

    puts "#{(index * instructions.size + other_index) / instructions.size**2.0 * 100}%"
    puts "#{(index * instructions.size + other_index)} / #{instructions.size**2}"
    puts

  end
end


html = "<html>"
html << "<table>"

html << "<tr>"
html << "<td></td>"
instructions.each_with_index do |instruction|
  html << %Q{<th scope="col">#{instruction.name}</th>}
end
html << "</tr>"

instructions.each_with_index do |instruction, index|
  html << "<tr>"
  html << %Q{<th scope="row">#{instruction.name}</th>}

  instructions.each_with_index do |other_instruction, other_index|
    dist = dists[index][other_index]
    color = heat_color dist, min_dist, max_dist
    html << %Q{<td style="background-color: #{color}">#{dist}</td>}
  end

  html << "</tr>"
end

html << "</table>"
html << "</html>"

File.write 'out.csv', YAML.dump(dists)
File.write 'out.html', html
