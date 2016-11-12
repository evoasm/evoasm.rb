define print_program
  set $i = 0
  set $i_ = $arg0->size
  while($i < $i_)
    set $j = 0
    set $j_ = $arg0->kernels[$i].size
    while($j < $j_)
      p (evoasm_x64_inst_id_t) $arg0->kernels[$i].insts[$j]
      set $j = $j + 1
    end
    set $i = $i + 1
  end
end

define aa
  finish
  continue
  if (loss < deme->best_loss)
    print loss
    #print_program deme->program
  else
    continue
  end
end

define print_tested_program
  set breakpoint pending on
  break evoasm_deme_test_program
  commands
    aa
  end
end

define print_evald_programs
  set breakpoint pending on
  break evoasm_program_eval
  commands
    print_program program
    continue
  end
end
