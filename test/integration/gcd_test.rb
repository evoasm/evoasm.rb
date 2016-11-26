require 'evoasm/test'
require 'evoasm/population'
require 'evoasm/prng'
require 'population_helper'

Evoasm.min_log_level = :warn
require 'pp'
module Search
  class GCDTest < Minitest::Test
    include PopulationHelper
    include PopulationHelper::Tests

    SEED = Array.new(Evoasm::PRNG::SEED_SIZE) { rand(10000) }

    def setup
      set_default_parameters

      @instruction_names = Evoasm::X64.instruction_names(:gp, :rflags)
      i = @instruction_names
      #@instruction_names = @instruction_names.grep /(add|cmp_|sub|not|rcr|rcl|neg|adc|and|bextr|blsi|blsmsk|mul|set|blsr|bsf|bsr|bswap|bt_|btc|btr|bts|bzhi|dec|div|inc)/
      #@instruction_names.concat [:cbw, :cwde, :cdqe, :clc, :cmc, :cwd, :cdq, :cqo, :lahf]
      #@instruction_names.concat [:mov_rm8_r8, :mov_rm16_r16, :mov_rm32_r32, :mov_rm64_r64, :mov_r8_rm8, :mov_r16_rm16, :mov_r32_rm32, :mov_r64_rm64, :mov_r8_imm8, :mov_r16_imm16, :mov_r32_imm32, :mov_rm8_imm8, :mov_rm16_imm16, :mov_rm32_imm32, :mov_rm64_imm32]
      #@instruction_names = @instruction_names.grep /(set)/
      #@instruction_names = i
      p i - @instruction_names

      #@instruction_names = @instruction_names.grep_v /div/
      p @instruction_names
      #p @instruction_names.size
      #@instruction_names = @instruction_names.reject {|i| i =~ /(r|rm)(16|8)/}
      #p @instruction_names.size
      #p Evoasm::X64.instruction_names(:gp, :rflags)[0..85] - Evoasm::X64.instruction_names(:gp, :rflags)[0..80]

      @examples = {
        [5, 1] => 1,
        [15, 5] => 5,
        [8, 2] => 2,
        [8, 4] => 4,
        [8, 6] => 2,
        [16, 8] => 8
      }
      p SEED

      @seed = SEED
      @kernel_size = 20
      @program_size = 5
      @mutation_rate = 0.0;
      @deme_count = 5
      @recur_limit = 100
      #@deme_size = 5000
      #@mutation_rate = 0.2
      @parameters = %i(reg0 reg1 reg2 reg3)

      unless self.name == 'test_consistent_progress'
        start
      end
    end

    make_my_diffs_pretty!

    def test_program_run
      # should generalize (i.e. give correct answer for non-training data)
      #assert_equal 2, found_program.run(16, 6)
      #assert_equal 1, found_program.run(15, 2)
    end
  end
end
