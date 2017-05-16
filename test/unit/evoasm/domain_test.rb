require 'evoasm/test'
require 'evoasm/domain'
require 'evoasm/prng'

module Evoasm
  class DomainTest < Minitest::Test

    def setup
      @prng = PRNG.new
    end

    def test_enumeration_domain
      enumeration_domain = Evoasm::EnumerationDomain.new 1, 2, 3, 4
      assert_equal [1, 2, 3, 4], enumeration_domain.values
      assert_equal 4, enumeration_domain.length
    end

    def test_range_domain
      range_domain = Evoasm::RangeDomain.new -10, 100
      assert_equal -10, range_domain.min
      assert_equal 100, range_domain.max

      100.times do
        assert_operator range_domain.rand(@prng), :>=, -10
        assert_operator range_domain.rand(@prng), :<=, 100
      end

      range_domain = Evoasm::RangeDomain.new 10, 100_000
      assert_equal 10, range_domain.min
      assert_equal 100_000, range_domain.max
    end

    def test_type_domain
      type_domain = Evoasm::RangeDomain.new :int8
      assert_equal :int8, type_domain.type
      assert_equal -2**7, type_domain.min
      assert_equal 2**7 - 1, type_domain.max

      type_domain = Evoasm::RangeDomain.new :int16
      assert_equal :int16, type_domain.type
      assert_equal -2**15, type_domain.min
      assert_equal 2**15 - 1, type_domain.max

      type_domain = Evoasm::RangeDomain.new :int32
      assert_equal :int32, type_domain.type
      assert_equal -2**31, type_domain.min
      assert_equal 2**31 - 1, type_domain.max

      type_domain = Evoasm::RangeDomain.new :int64
      assert_equal :int64, type_domain.type
      assert_equal -2**63, type_domain.min
      assert_equal 2**63 - 1, type_domain.max
    end
  end
end