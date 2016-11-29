require 'evoasm/error'
require 'ffi'

module Evoasm
  class Population < FFI::AutoPointer

    # @return [Population::Parameters] population parameters
    attr_reader :parameters

    # @!visibility private
    def self.release(ptr)
      Libevoasm.pop_destroy(ptr)
      Libevoasm.pop_free(ptr)
    end

    # @param architecture [Symbol] architecture, currently only +:x64+ is supported
    # @param parameters [Population::Parameters] the population parameters
    def initialize(architecture, parameters)
      @parameters = parameters

      ptr = Libevoasm.pop_alloc
      unless Libevoasm.pop_init ptr, architecture, @parameters
        raise Error.last
      end

      super(ptr)
    end

    # Evaluates all programs and kernels in the population
    # @return [void]
    def evaluate
      unless Libevoasm.pop_eval self
        raise Error.last
      end
    end

    # Seeds the population with random individuals
    # @return [void]
    def seed
      Libevoasm.pop_seed self
    end

    # @return [Float] the loss of the best program found so far
    # @see #best_program
    def best_loss
      Libevoasm.pop_get_best_loss self
    end

    # @return [Program] the best program found so far
    def best_program
      program = Program.new
      unless Libevoasm.pop_load_best_program self, program
        raise Error.last
      end

      program
    end

    # @!visibility private
    def loss_samples
      Array.new(@parameters.deme_count) do |deme_index|
        data_ptr_ptr = FFI::MemoryPointer.new :pointer, 1
        len = Libevoasm.pop_get_loss_samples self, deme_index, data_ptr_ptr
        data_ptr = data_ptr_ptr.read_pointer
        data_ptr.read_array_of_float len
      end
    end

    # Gives a five-number summary for each deme, program and kernel.
    # @return [Array] a 2-dimensional array of summaries.
    def summary(flat: false)
      summary_len = Libevoasm.pop_summary_len self
      summary_ptr = FFI::MemoryPointer.new :float, summary_len
      unless Libevoasm.pop_calc_summary self, summary_ptr
        raise Error.last
      end

      summary = summary_ptr.read_array_of_float(summary_len).each_slice(summary_len / @parameters.deme_count).to_a
      unless flat
        summary.map!{|deme_summary| deme_summary.each_slice(5).to_a}
      end

      summary
    end

    # Execute a single generational cycle
    # @return [void]
    def next_generation!
      Libevoasm.pop_next_gen self
    end

    # Plots the loss function
    # @return [void]
    def plot
      @plotter ||= Plotter.new self
      @plotter.update
      @plotter.plot
    end

    # Starts the evolutionary process on this population
    # @param min_generations [Integer] minimum number of generations to run
    # @param max_generations [Integer] maximum number of generations to run
    # @yield [self]
    # @yieldreturn a truthy value to stop the process
    # @return [Program] the best program found

    def run(min_generations: 0, max_generations: 1000, &block)
      best_program = nil
      generation = 0
      best_loss = Float::INFINITY

      until (generation > min_generations && best_program) || generation > max_generations
        evaluate

        if block
          break if block[self]
        end

        next_generation!
        generation += 1
      end

      best_program
    end
  end
end

require 'evoasm/population/parameters'
require 'evoasm/population/plotter'
