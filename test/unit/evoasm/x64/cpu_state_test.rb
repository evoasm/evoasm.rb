require 'evoasm/test'
require 'evoasm/x64/cpu_state'
require 'evoasm/buffer'

module Evoasm
  module X64
    class CPUStateTest < Minitest::Test
      def setup
        @cpu_state = CPUState.new
      end

      def test_clean
        X64.registers.each do |reg|
          data = @cpu_state.get(reg)
          refute_empty data
          assert data.all? { |e| e == 0}
        end
      end

      def test_set_get
        @cpu_state.set :a, 0xFF
        assert_equal [0xFF], @cpu_state.get(:a)

        @cpu_state.set :b, [0xDEADBEEF]
        assert_equal [0xDEADBEEF], @cpu_state.get(:b)

        # FIXME: with AVX512 the array
        # should be of size 8
        data = (1..4).to_a
        @cpu_state.set :xmm0, data
        assert_equal data, @cpu_state.get(:xmm0)
      end

      def test_clone
        @cpu_state.set :b, 0xFAB
        cloned_cpu_state = @cpu_state.clone

        assert_equal [0xFAB], cloned_cpu_state.get(:b)
      end

      def test_emit_store
        buffer = Buffer.new :mmap, 1024
        Evoasm::X64.encode(:mov_rm32_imm32, {reg0: :a, imm: 7}, buffer)

        @cpu_state.emit_store buffer
        Evoasm::X64.encode(:ret, {}, buffer)

        buffer.__log__ :warn

        buffer.execute

        assert_equal [7], @cpu_state.get(:a)

      end
    end
  end
end