# @title Instruction Similarity
# Instruction Similarity

Using *Evoasm*'s {Evoasm::X64::CPUState} class it's possible to analyze
how an instruction modifies the CPU's registers.

The following examples finds for each instruction the 32 most similar instructions
by running each on a random CPU state and comparing the results.

The result is visualized in [this table](examples/inst_dist.html).

{include:file:docs/examples/inst_dist.rb}


