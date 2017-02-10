require 'open3'

module Evoasm
  class Population

    # Visualizes the population loss functions using {http://gnuplot.sourceforge.net Gnuplot}
    class Plotter
      MAX_SAMPLE_COUNT = 16

      # @!visibility private
      def self.__open__
        return @pipe if @pipe
        @pipe, = Open3.popen3('gnuplot')
        @pipe
      end

      # @param population [Population] the population to plot
      def initialize(population, filename = nil)
        @population = population

        @pipe = self.class.__open__

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
        @sample_tail = 0
        @sample_count = 0
        @data = Array.new(@deme_count) { Array.new MAX_SAMPLE_COUNT }
      end

      # Updates data points
      # @return [nil]
      def update
        summary = @population.summary

        summary.each_with_index do |deme_summary, deme_index|
          deme_samples = @data[deme_index]
          deme_samples[@sample_tail] = [@population.generation] + deme_summary
        end

        @sample_count = [@sample_count + 1, MAX_SAMPLE_COUNT].min
        @sample_tail = (@sample_tail + 1) % MAX_SAMPLE_COUNT
      end

      # Plots (or replots) the current data points
      # @return [void]
      def plot
        @pipe.puts "set multiplot layout 1, #{@deme_count}"

        key = true

        @deme_count.times do |deme_index|
          deme_summary = @data[deme_index]

          @pipe.puts "set key #{key ? 'on' : 'off'}"
          key = false
          @pipe.write %Q{plot '-' using 1:2:3 with filledcurves title 'IQR'}
          @pipe.write %Q{    ,'-' using 1:2 with lp title 'Min'}
          @pipe.write %Q{    ,'-' using 1:2:(sprintf("%.2f", $2)) with labels center offset 2,0.6 notitle}
          @pipe.write %Q{    ,'-' using 1:2 with lp lt 1 pt 5 ps 1.5 lw 2 title 'Median'}
          @pipe.write %Q{    ,'-' using 1:2:(sprintf("%.2f", $2)) with labels center offset 2,1 notitle}
          @pipe.puts

          write_samples deme_summary, 0, 2, 4

          write_samples deme_summary, 0, 1
          write_samples deme_summary, 0, 1

          write_samples deme_summary, 0, 3
          write_samples deme_summary, 0, 3
        end
        @pipe.puts "unset multiplot"
        @pipe.flush
      end

      private

      def write_samples(deme_summary, *value_indexes)
        @sample_count.times do |index|
          sample_index = (@sample_tail - @sample_count + MAX_SAMPLE_COUNT + index) % MAX_SAMPLE_COUNT
          line = value_indexes.map { |value_index| deme_summary[sample_index][value_index] }.join(' ')
          @pipe.puts line
        end
        @pipe.puts 'e'
      end

    end
  end
end