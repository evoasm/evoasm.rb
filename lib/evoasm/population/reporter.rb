require 'colorize'

module Evoasm
  class Population

    class Reporter
      # @!visibility private

      # @param population [Population] the population to report for
      def initialize(population)
        @population = population
        @deme_count = @population.parameters.deme_count
      end

      # Updates data points
      # @return [nil]
      def update
        @summary = @population.summary
        @generation = @population.generation
      end

      # Outputs statistics of last the update to the terminal
      # @return [void]
      def report
        puts "Generation #{@generation.to_s.bold}"
        print_table
      end

      private
      def print_table
        print_row '' do |deme_index|
          $stdout.write "Deme #{deme_index + 1}".underline
        end

        {'Min' => :green, 'Q1' => :white, 'Median' => :yellow, 'Q2' => :white, 'Max' => :red}.each_with_index do |(header, color), index|
          print_row header do |deme_index|
            value = @summary[deme_index][index]
            value_as_string = if value.infinite?
              'inf'
            else
              value.round(3).to_s
            end
            $stderr.write value_as_string.green.colorize(color)
          end
        end

        puts
        puts
      end

      def print_row(header, &block)
        $stdout.write "\t"
        $stdout.write header.underline
        $stdout.write "\t"

        @deme_count.times do |deme_index|
          block[deme_index]
          if deme_index == @deme_count - 1
            $stdout.write "\n"
          else
            $stdout.write "\t\t"
          end
        end
      end
    end
  end
end