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
  #puts "Running #{instruction.name} #{%i(reg0 reg1 reg2 imm0 reg0_high_byte? reg1_high_byte?).map {|p| parameters[p]}.inspect}"
  buffer.reset
  Evoasm::X64.emit_stack_frame buffer do
    cpu_state.emit_load buffer
    instruction.encode parameters, buffer
    cpu_state.emit_store buffer
  end

  begin
    buffer.execute!
  rescue Evoasm::ExceptionError => e
  end
end

dists = Array.new(instructions.size)

COLORS = [[1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 1, 1], [0, 0, 1]].freeze


def text_color(bg_color)
  luminance = 1 - (0.299 * bg_color[0] + 0.587 * bg_color[1] + 0.114 * bg_color[2]) / 255.0
  return 'black' if luminance < 0.5
  'white'
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
MAX_TRIES = 200

def select_best(dists)
  dists.sort_by {|hash| hash[:dist]}
    .take(64)
end

IMMS = [0, 1, -1, +2, -2, -8, 8, 0xFF, 0x0F, 0xF0, 0xFF00, 0xFF00FF00, 0b01010101, 0b10101010, 2**10, 2**15, 2**20, 2**30]
PARAMS = %i(reg0 reg1 reg2 reg3 imm0)

param_names_cache = []
imm_insts = []

instructions.each_with_index do |inst, inst_index|
  param_names = inst.parameters.map(&:name)
  param_names_cache[inst_index] = param_names
  imm_insts[inst_index] = param_names.include? :imm0
end

instructions.each_with_index do |inst, index|

  absdiff_dists = []
  hamming_dists = []

  instructions.each_with_index do |other_inst, other_index|

    n = 20

    if !imm_insts[index] && imm_insts[other_index]
      imms = IMMS
    else
      imms = [nil]
    end

    imms.each do |imm|

      mean_absdiff_dist = 0
      mean_hamming_dist = 0

      actual_n = 0
      tries = 0

      while actual_n < n && tries < MAX_TRIES
        parameters = Evoasm::X64::Parameters.random inst, other_inst

        tries += 1

        if parameters.nil?
          next
        end

        #p [parameters[:reg0], parameters[:reg1], parameters[:reg3]]

        parameters[:imm0] = imm if imm

        cpu_state = Evoasm::X64::CPUState.random
        other_cpu_state = cpu_state.clone

        begin
          run buffer, inst, parameters, cpu_state
          run buffer, other_inst, parameters, other_cpu_state

          absdiff_dist = cpu_state.distance(other_cpu_state, :absdiff)
          hamming_dist = cpu_state.distance(other_cpu_state, :hamming)

          if inst.name == other_inst.name
            raise "#{absdiff_dist}" unless absdiff_dist == 0
            raise "#{hamming_dist}" unless hamming_dist == 0
          end

          mean_absdiff_dist += absdiff_dist / n
          mean_hamming_dist += hamming_dist / n
          actual_n += 1
        rescue Evoasm::Error => e
          #puts [e.message, other_instruction.name]
        end
      end

      if actual_n > 0
        if mean_absdiff_dist < MAX_ABSDIFF_DIST || mean_hamming_dist < MAX_HAMMING_DIST

          additional_params = (param_names_cache[other_index] - param_names_cache[index]) & PARAMS

          if mean_absdiff_dist < MAX_ABSDIFF_DIST
            absdiff_dists << {inst: other_inst.name, dist: mean_absdiff_dist, imm: imm, params: additional_params}
          end

          if mean_hamming_dist < MAX_HAMMING_DIST
            hamming_dists << {inst: other_inst.name, dist: mean_hamming_dist, imm: imm, params: additional_params}
          end

        end
      end
    end
  end

  dists[index] = {
    absdiff: select_best(absdiff_dists),
    hamming: select_best(hamming_dists),
  }

  puts "#{(index / instructions.size.to_f * 100).to_i}%"
  puts "#{index} / #{instructions.size}"
  puts
end


html = "<html>"
html << "<table>"
instructions.each_with_index do |instruction, index|

  dists[index].each_with_index do |(_, inst_dists), index|
    html << "<tr>"
    html << %(<th scope="row" rowspan="2">#{instruction.name}</th>) if index == 0

    max_dist = index.zero? ? MAX_ABSDIFF_DIST : MAX_HAMMING_DIST

    inst_dists.each do |hash|
      dist = hash[:dist]
      imm = hash[:imm]
      other_inst_name = hash[:inst]
      bg_color, text_color = heat_color dist, 0, max_dist
      html << %(<td style="background-color: #{bg_color}; color: #{text_color}">#{other_inst_name}/#{dist.round 3} (#{imm})</td>)
    end
    html << "</tr>"
  end


end

html << "</table>"
html << "</html>"

File.write File.join(__dir__, 'inst_dist.yml'), YAML.dump(instruction_names.zip(dists).to_h)
File.write File.join(__dir__, 'inst_dist.html'), html
