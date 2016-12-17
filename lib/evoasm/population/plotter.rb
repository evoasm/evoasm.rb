module Evoasm
  class Population

    # Visualizes the population loss functions using {http://gnuplot.sourceforge.net Gnuplot}
    class Plotter
      MAX_SAMPLE_COUNT = 64

      # @!visibility private
      def self.__open__
        @pipe ||= IO.popen('gnuplot -persist', 'w')
      end

      # @param population [Population] the population to plot
      def initialize(population, filename = nil)
        @population = population

        @pipe = self.class.__open__
        #@pipe = File.open('/tmp/test.txt', 'w')

        if filename
          case filename
          when /\.gif$/
            @pipe.puts 'set term gif animate delay 20 size 1280, 1024 crop'
            @pipe.puts %Q{set output "#{filename}"}
          else
            raise ArgumentError, "unknown output filetype"
          end
        end

        @pipe.puts 'set xtics'
        @pipe.puts 'set ytics'
        @pipe.puts 'set grid'
        @pipe.puts 'set style fill transparent solid 0.2 noborder'
        @pipe.puts 'set datafile missing "Infinity"'
        @pipe.puts 'set lmargin 0.5'
        @pipe.puts 'set rmargin 0.5'
        @pipe.puts 'set tmargin 0.5'
        @pipe.puts 'set bmargin 0.5'

        @deme_count = @population.parameters.deme_count
        @deme_height = @population.parameters.deme_height
        @sample_index = 0
        @data = Array.new(@deme_count) { Array.new(@deme_height) { Array.new MAX_SAMPLE_COUNT } }
      end

      # Updates data points
      # @return [nil]
      def update
        summary = @population.summary

        summary.each_with_index do |deme_summary, deme_index|
          deme_summary.each_with_index do |layer_summary, layer_index|
            samples = @data[deme_index][layer_index]
            samples[@sample_index] = [@population.generation] + layer_summary
          end
        end

        @sample_index = (@sample_index + 1) % MAX_SAMPLE_COUNT
      end

      # Plots (or replots) the current data points
      # @return [void]
      def plot
        @pipe.puts "set multiplot layout #{@deme_height}, #{@deme_count}"

        key = true

        @deme_count.times do |deme_index|
          @deme_height.times do |layer_index|

            layer_summary = @data[deme_index][layer_index]

            @pipe.puts "set key #{key ? 'on' : 'off'}"
            key = false
            @pipe.write %Q{plot '-' using 1:2:3 with filledcurves title 'IQR'}
            @pipe.write %Q{    ,'-' using 1:2 with lp title 'Min'}
            @pipe.write %Q{    ,'-' using 1:2:(sprintf("%.2f", $2)) with labels center offset 2,0.6 notitle}
            @pipe.write %Q{    ,'-' using 1:2 with lp lt 1 pt 5 ps 1.5 lw 2 title 'Median'}
            @pipe.write %Q{    ,'-' using 1:2:(sprintf("%.2f", $2)) with labels center offset 2,1 notitle}
            @pipe.puts

            write_samples layer_summary, 0, 2, 4

            write_samples layer_summary, 0, 1
            write_samples layer_summary, 0, 1

            write_samples layer_summary, 0, 3
            write_samples layer_summary, 0, 3
          end
        end
        @pipe.puts "unset multiplot"
        @pipe.flush
      end

      private

      def write_samples(layer_summary, *value_indexes)
        @sample_index.times do |sample_index|
          line = value_indexes.map { |value_index| layer_summary[sample_index][value_index] }.join(' ')
          @pipe.puts line
        end
        @pipe.puts 'e'
      end

    end
  end
end