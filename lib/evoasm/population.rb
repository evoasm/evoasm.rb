require 'evoasm/error'
require 'ffi'

module Evoasm
  class Population < FFI::AutoPointer

    # @return [Population::Parameters] population parameters
    attr_reader :parameters
    attr_reader :architecture

    # @!visibility private
    def self.release(ptr)
      Libevoasm.pop_destroy(ptr)
      Libevoasm.pop_free(ptr)
    end

    # @param parameters [Population::Parameters] the population parameters
    # @param architecture [Symbol] architecture, currently only +:x64+ is supported
    def initialize(parameters, architecture = Evoasm.architecture)
      @parameters = parameters
      @architecture = architecture

      ptr = Libevoasm.pop_alloc
      unless Libevoasm.pop_init ptr, @architecture, @parameters
        raise Error.last
      end

      super(ptr)
    end

    # Evaluates all kernels and kernels in the population
    # @return [void]
    def evaluate(minor_generations = 5)
      unless Libevoasm.pop_eval self, minor_generations
        raise Error.last
      end
    end

    # @return [Integer] the current generation
    def generation
      Libevoasm.pop_get_gen_counter self
    end

    # Seeds the population with random individuals
    # @return [void]
    def seed(&block)
      if block
        seed_builder = SeedBuilder.new self, self.parameters.instructions, &block
        seed_builder.seed_population!
      else
        Libevoasm.pop_seed self, FFI::Pointer::NULL
      end

    end

    # @return [Float] the loss of the best kernel found so far
    # @see #best_kernel
    def best_loss
      Libevoasm.pop_get_best_loss self
    end

    # @return [Kernel] the best kernel found so far
    def best_kernel
      kernel = Libevoasm.kernel_alloc
      unless Libevoasm.pop_load_best_kernel self, kernel
        raise Error.last
      end

      Kernel.wrap kernel
    end

    # @!visibility private
    # def loss_samples
    #   Array.new(@parameters.deme_count) do |deme_index|
    #     data_ptr_ptr = FFI::MemoryPointer.new :pointer, 1
    #     len = Libevoasm.pop_get_loss_samples self, deme_index, data_ptr_ptr
    #     data_ptr = data_ptr_ptr.read_pointer
    #     data_ptr.read_array_of_float len
    #   end
    # end

    # Gives a five-number summary for each deme, kernel and kernel.
    # @return [Array] a 2-dimensional array of summaries.
    def summary(flat: false)
      summary_len = Libevoasm.pop_summary_len self
      summary_ptr = FFI::MemoryPointer.new :float, summary_len
      unless Libevoasm.pop_calc_summary self, summary_ptr
        raise Error.last
      end

      summary = summary_ptr.read_array_of_float(summary_len).each_slice(summary_len / @parameters.deme_count).to_a
      # unless flat
      #   summary.map!{|deme_summary| deme_summary.each_slice(5).to_a}
      # end

      summary
    end

    # Execute a single generational cycle
    # @return [void]
    def next_generation!
      Libevoasm.pop_next_gen self
    end

    # Stops the process started by {#run}
    # @return [void]
    def stop
      @stop = true
    end

    # Plots the loss function
    # @return [void]
    def plot(filename = nil)
      @plotter ||= Plotter.new self, filename
      @plotter.update
      @plotter.plot
    end

    # Starts the evolutionary process on this population
    # @param loss [Float] stop process if a kernel is found whose loss is less or equal than the specified loss
    # @param min_generations [Integer] minimum number of generations to run
    # @param max_generations [Integer] maximum number of generations to run
    # @param seed [Bool] whether the population should be seeded before starting
    # @yield [self]
    # @yieldreturn a truthy value to stop the process
    # @return [Kernel] the best kernel found

    def run(loss: nil, min_generations: nil, max_generations: 10, seed: true, &block)
      self.seed if seed
      best_loss = nil

      loop do
        evaluate

        best_loss = self.best_loss
        generation = self.generation

        block[self, generation]

        break if @stop
        min_generations_reached = min_generations.nil? || generation >= min_generations
        break if min_generations_reached && loss && best_loss <= loss
        break if max_generations && generation >= max_generations

        next_generation!
      end

      @stop = false

      best_kernel = self.best_kernel
      return best_kernel, best_loss
    end
  end
end

require 'evoasm/population/parameters'
require 'evoasm/population/seed_builder'
require 'evoasm/population/plotter'
