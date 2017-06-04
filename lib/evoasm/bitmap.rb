require 'evoasm/ffi_ext'
require 'evoasm/prng'

module Evoasm
  # @!visibility private
  class Bitmap < FFI::AutoPointer
    include Enumerable

    attr_reader :size

    class << self
      def release(ptr)
        Libevoasm.bitmap_free ptr
      end

      def new(size)
        ptr = Libevoasm.bitmap_alloc size
        Libevoasm.bitmap_init(ptr, size)
        super(ptr, size)
      end
    end

    def initialize(ptr, size)
      super(ptr)
      @size = size
    end

    def inspect
     "#<#{self.class.inspect} #{to_a.map { |value| value ? '1' : '0' }.join('')}>"
    end

    def to_a
      Array.new(size) do |index|
        self[index]
      end
    end

    def each
      return enum_for(:each) unless block_given?

      size.times do |index|
        yield self[index]
      end
    end

    def [](index)
      check_index index
      Libevoasm.bitmap_get self, index
    end

    def []=(index, value)
      check_index index
      Libevoasm.bitmap_set_to self, index, value
    end

    def set(index)
      check_index index
      Libevoasm.bitmap_set self, index
    end

    def unset(index)
      check_index index
      Libevoasm.bitmap_unset self, index
    end

    private

    def check_index(index)
      if index >= size || index < 0
        raise IndexError, "index #{index} exceeds size #{size}"
      end
    end

  end
end
