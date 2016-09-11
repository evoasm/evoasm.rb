require_relative 'test_helper'

require 'evoasm/prng'

class PRNGTest < Minitest::Test
  def setup
    @prng = Evoasm::PRNG.new
  end

  def test_same_seed
    same_prng = Evoasm::PRNG.new

    10.times do
      assert_equal @prng.rand64, same_prng.rand64
    end
  end

  def test_different_seed
    other_prng = Evoasm::PRNG.new (11..26).to_a

    refute_equal @prng.rand64, other_prng.rand64
  end

  def test_rand8
    buckets = Array.new(256, 0)
    sample_size = 100_000
    sample_size.times do
      r = @prng.rand8
      refute_operator r, :>, 255
      refute_operator r, :<, 0
      buckets[r] += 1
    end

    # Not sufficient,
    # but indicates if something is seriously wrong
    exp_bucket_size = sample_size / buckets.size
    mse = 1.0/buckets.size * buckets.inject(0) do |acc, sample|
      diff = ((sample - exp_bucket_size.to_f)**2 / exp_bucket_size.to_f)
      p [sample, exp_bucket_size, diff]
      acc + diff
    end

    rmse = Math.sqrt mse
    assert_operator rmse, :<, 2.0
  end
end