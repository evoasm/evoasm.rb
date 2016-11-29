module Evoasm
  class Population

    # Visualizes the population loss functions using {http://gnuplot.sourceforge.net Gnuplot}
    class Plotter
      MAX_SAMPLE_COUNT = 1024

      # @!visibility private
      def self.__open__
        @pipe ||= IO.popen('gnuplot -persist', 'w')
      end

      # @param population [Population] the population to plot
      def initialize(population)
        @population = population

        @pipe = self.class.__open__
        #@pipe = File.open('/tmp/test.txt', 'w')
        @pipe.puts 'set xtics'
        @pipe.puts 'set ytics'
        @pipe.puts 'set grid'
        @pipe.puts 'set style fill transparent solid 0.2 noborder'
        @pipe.puts 'set datafile missing "Infinity"'
      end

      # Updates data points
      # @return [nil]
      def update
        @data ||= Array.new(@population.parameters.deme_count) { Array.new(@population.parameters.deme_height) { [] } }
        summary = @population.summary

        summary.each_with_index do |deme_summary, deme_index|
          deme_summary.each_with_index do |layer_summary, layer_index|
            samples = @data[deme_index][layer_index]
            samples[samples.size % MAX_SAMPLE_COUNT] = layer_summary
          end
        end
      end

      # Plots (or replots) the current data points
      # @return [nil]
      def plot
        @pipe.puts "set multiplot layout #{@data[0].size}, #{@data.size}"

        @data.each do |deme_summary|
          deme_summary.each do |layer_summary|
            @pipe.write  %Q{plot '-' using 1:2:3 with filledcurves title 'IQR',}
            @pipe.write %Q{      '-' using 1:2 with lp title 'Min',}
            @pipe.puts  %Q{      '-' using 1:2 with lp lt 1 pt 5 ps 1.5 lw 2 title 'Median'}

            layer_summary.each_with_index do |sample, sample_index|
              @pipe.puts "#{sample_index} #{sample[1]} #{sample[3]}"
            end
            @pipe.puts 'e'
            layer_summary.each_with_index do |sample, sample_index|
              @pipe.puts "#{sample_index} #{sample[0]}"
            end
            @pipe.puts 'e'
            layer_summary.each_with_index do |sample, sample_index|
              @pipe.puts "#{sample_index} #{sample[2]}"
            end
            @pipe.puts 'e'
          end
        end
        @pipe.puts "unset multiplot"
        @pipe.flush
      end
    end
  end
end
