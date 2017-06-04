require 'evoasm/test'
require 'evoasm/bitmap'

module Evoasm
  class BitmapTest < Minitest::Test

    def setup
      @bitmap = Bitmap.new 1024
    end

    def test_initialize
      @bitmap.each do |value|
        assert_equal false, value
      end
    end

    def test_get
      assert_raises IndexError do
        @bitmap[1024]
      end
    end

    def test_set
      set_index = 10
      @bitmap.set set_index
      @bitmap.each.with_index do |value, index|
        if index == set_index
          assert_equal true, value
        else
          assert_equal false,value
        end
      end
    end

    def test_unset
      index = 10
      @bitmap.set index
      @bitmap.set index + 1
      @bitmap.set index - 1
      @bitmap.unset index

      assert_equal false,@bitmap[index]
      assert_equal true,@bitmap[index + 1]
      assert_equal true,@bitmap[index - 1]

      assert_raises IndexError do
        @bitmap.set(1024)
      end

      assert_raises IndexError do
        @bitmap.unset(1024)
      end
    end

    def test_set_to
      index = 10
      @bitmap[index] = true
      assert_equal true,@bitmap[index]
      @bitmap[index] = false
      assert_equal false,@bitmap[index]

      assert_raises IndexError do
        @bitmap[1024] = false
      end
    end
  end
end