begin
  require 'evoasm'
  require 'evoasm/x64'
  require 'evoasm/x64/cpu_state'
rescue LoadError
  $LOAD_PATH.unshift '../lib'
end

require 'yaml'

instruction_names = Evoasm::X64::instruction_names(:gp, :rflags, :xmm)
instructions = instruction_names.map do |name|
  Evoasm::X64.instruction name
end


buffer = Evoasm::Buffer.new 1024, :mmap

def run(buffer, instruction, parameters, cpu_state)
  buffer.reset
  Evoasm::X64.emit_stack_frame buffer do
    cpu_state.emit_load buffer
    instruction.encode parameters, buffer
    cpu_state.emit_store buffer
  end

  begin
    buffer.execute!
  rescue Evoasm::ExceptionError
  end
end

dists = Array.new(instructions.size)

COLORS = [[1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 1, 1], [0, 0, 1]].freeze


def text_color(bg_color)
  luminance = 1 - ( 0.299 * bg_color[0] + 0.587 * bg_color[1] + 0.114 * bg_color[2]) / 255.0
  return 'black' if luminance < 0.5
  return 'white';
end


def heat_color(dist, min_dist, max_dist)
  return ["black", "white"] if dist.nil?

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

  text_color = text_color(heat_color)
  bg_color = "#%02x%02x%02x".%(heat_color)

  [bg_color, text_color]
end

MAX_ABSDIFF_DIST = 1000
MAX_HAMMING_DIST = 0.15

def select_best(instruction_names, dists, max)
  instruction_names.zip(dists).select{ |_, d| d && d <= max }.sort_by{ |_, d| d}.take(64).to_h
end

instructions.each_with_index do |instruction, index|

  absdiff_dists = Array.new(instructions.size, 0)
  hamming_dists = Array.new(instructions.size, 0)

  instructions.each_with_index do |other_instruction, other_index|

    n = 200
    n.times do
      parameters = Evoasm::X64::Parameters.random instruction

      cpu_state = Evoasm::X64::CPUState.random
      other_cpu_state = cpu_state.clone

      begin
        run buffer, instruction, parameters, cpu_state
        run buffer, other_instruction, parameters, other_cpu_state

        absdiff_dist = cpu_state.distance(other_cpu_state, :absdiff)
        hamming_dist = cpu_state.distance(other_cpu_state, :hamming)

        if instruction.name == other_instruction.name
          raise "#{absdiff_dist}" unless absdiff_dist == 0
          raise "#{hamming_dist}" unless hamming_dist == 0
        end

        absdiff_dists[other_index] += absdiff_dist / n
        hamming_dists[other_index] += hamming_dist / n
      rescue Evoasm::Error => e
        absdiff_dists[other_index] = nil
        hamming_dists[other_index] = nil
        puts e.message
        break
      end
    end
  end

  dists[index] = {
    absdiff: select_best(instruction_names, absdiff_dists, MAX_ABSDIFF_DIST),
    hamming: select_best(instruction_names, hamming_dists, MAX_HAMMING_DIST),
  }

  puts "#{(index / instructions.size.to_f * 100).to_i}%"
  puts "#{index} / #{instructions.size}"
  puts
end


html = "<html>"
html << "<table>"
instructions.each_with_index do |instruction, index|

  dists[index].each_with_index do |(_, d), index|
    html << "<tr>"
    html << %(<th scope="row" rowspan="2">#{instruction.name}</th>) if index == 0

    max_dist = index.zero? ? MAX_ABSDIFF_DIST : MAX_HAMMING_DIST

    d.each do |other_instruction_name, dist|
      bg_color, text_color = heat_color dist, 0, max_dist
      html << %(<td style="background-color: #{bg_color}; color: #{text_color}">#{other_instruction_name}/#{dist.round 3}</td>)
    end
    html << "</tr>"
  end


end

html << "</table>"
html << "</html>"

File.write  File.join(__dir__, 'inst_dist.yml'), YAML.dump(instruction_names.zip(dists).to_h)
File.write File.join(__dir__, 'inst_dist.html'), html
