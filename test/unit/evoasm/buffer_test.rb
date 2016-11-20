require 'evoasm/test'
require 'evoasm/x64'
require 'evoasm/buffer'

module Evoasm
  class BufferTest < Minitest::Test
    def setup
      @mmap_buffer = Buffer.new(:mmap, 1024)
      @malloc_buffer = Buffer.new(:malloc, 1024)
    end

    def test_type
      assert_equal :mmap, @mmap_buffer.type
      assert_equal :malloc, @malloc_buffer.type
    end

    def test_capacity
      assert_equal 1024, @mmap_buffer.capacity
      assert_equal 1024, @malloc_buffer.capacity
    end

    def test_position
      assert_equal 0, @mmap_buffer.position
      assert_equal 0, @malloc_buffer.position
    end

    def test_to_s
      assert_equal "\0" * @mmap_buffer.capacity, @mmap_buffer.to_s
      assert_equal @malloc_buffer.capacity, @malloc_buffer.to_s.size
    end

    def test_write
      data = "\xA\xB\xC"
      @mmap_buffer.write data
      assert_equal data, @mmap_buffer.to_s[0...data.size]
    end

    def test_execute
      Evoasm::X64.encode(:mov_rm32_imm32, {reg0: :a, imm0: 7}, @mmap_buffer)
      Evoasm::X64.encode(:ret, {}, @mmap_buffer)

      #@mmap_buffer.__log__ :warn

      assert_equal 7, @mmap_buffer.execute!
    end

  end
end