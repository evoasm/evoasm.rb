# Getting Started

## Symbolic Regression

A classical application of genetic programming is [symbolic regression](https://en.wikipedia.org/wiki/Symbolic_regression).
Symbolic regression is the task of finding a mathematical expression that closely
approximates a given set of data points.

For purposes of illustration, assume we are given the following
table of data points, sampled from the function `y = sqrt(x**3 + 2 * x)`.

| x  | y |
| ------- | ----- |
| 0.0 | 0.0 |
| 0.5 | 1.0606601717798212 |
| 1.0 | 1.7320508075688772 |
| 1.5 | 2.5248762345905194 |
| 2.0 | 3.4641016151377544 |
| 2.5 | 4.541475531146237  |
| 3.0 | 5.744562646538029  |
| 3.5 | 7.0622234459127675 |
| 4.0 | 8.48528137423857   |
| 4.5 | 10.00624804809475  |
| 5.0 | 11.61895003862225  |

Using only the points in this table, we now want *Evoasm*
to come up with a program that, given `x`, will output the
 corresponding `y = sqrt(x**3 + 2 * x)` for all `x` (i.e. not only those listed in the table).

Here is how it is done:
 
```ruby
require 'evoasm'

examples = {
  0.0 => 0.0,
  0.5 => 1.0606601717798212,
  1.0 => 1.7320508075688772,
  1.5 => 2.5248762345905194,
  2.0 => 3.4641016151377544,
  2.5 => 4.541475531146237,
  3.0 => 5.744562646538029,
  3.5 => 7.0622234459127675,
  4.0 => 8.48528137423857,
  4.5 => 10.00624804809475,
  5.0 => 11.61895003862225
}

search = Evoasm::Search.new :x64 do |p|

  program_deme
  # operating on XMM registers and whose name contains
  # either add, mul, or sqrt.
  instruction_names = Evoasm::X64.instruction_names(:xmm, search: true)
                                 .grep /(add|mul|sqrt).*?sd/
  p.instructions = instruction_names
  
  # Programs should be at least 5,
  # but no longer than 15 instructions
  p.kernel_size = (5..15)
  
  # We only need a single kernel
  p.program_size = 1
  
  p.population_size = 1600
  
  program_deme
  # In this example, it's all about finding
  # the right register combinations
  p.parameters = %i(reg0 reg1 reg2 reg3)

  # Programs should only make use  of
  # registers XMM0 through XMM3
  regs = %i(xmm0 xmm1 xmm2 xmm3)
  p.domains = {
    reg0: regs,
    reg1: regs,
    reg2: regs,
    reg3: regs
  }
  
  # Consider only programs
  # with zero loss
  p.min_loss = 0.0

  p.examples = examples
end

found_program = nil

program_deme
search.start! do |program, loss|
  puts program.disassemble
  found_program = program
  
  # Stop search
  false
end

```
On my machine, *Evoasm* will find a solution in less than a second:

```
0x555556ceb620:  mulsd   xmm2, xmm1
0x555556ceb624:  vfmadd132sd   xmm3, xmm0, xmm2
0x555556ceb629:  vaddsd   xmm0, xmm1, xmm2
0x555556ceb62d:  vfnmadd132sd   xmm2, xmm1, xmm2
0x555556ceb632:  vaddsd   xmm1, xmm3, xmm1
0x555556ceb636:  vfmadd132sd   xmm0, xmm3, xmm1
0x555556ceb63b:  mulsd   xmm2, xmm2
0x555556ceb63f:  vsqrtsd   xmm2, xmm3, xmm2
0x555556ceb643:  vfmadd132sd   xmm0, xmm3, xmm3
0x555556ceb648:  sqrtsd   xmm1, xmm1
0x555556ceb64c:  vsqrtsd   xmm2, xmm2, xmm2
0x555556ceb650:  vfmadd231sd   xmm2, xmm3, xmm0
```

You can now experiment with the found program (Automatically Defined Function).

```ruby
> program.run 1.0  # => [1.7320508075688772]
# test for values not given in table
> program.run 10.0 # => [31.937438845342623]
```

### Intron Elimination
The solutions found by *Evoasm* will usually contain large 
portions of noneffective code (so-called introns).

Introns can be removed using the `eliminate_introns!` method.
This will considerably shorten the size of the solution:

```ruby
> program.eliminate_introns!
> program.disassemble # => ["0x555556ceb620:  mulsd   xmm2, xmm1",
                      #     "0x555556ceb624:  vfmadd132sd   xmm3, xmm0, xmm2",
                      #     "0x555556ceb629:  vaddsd   xmm1, xmm3, xmm1",
                      #     "0x555556ceb62d:  sqrtsd   xmm1, xmm1"]
```

For comparison, here is what GCC 6.2 outputs with `-O3 -march=core-avx2`
```
vmulsd  %xmm0, %xmm0, %xmm2
vaddsd  %xmm0, %xmm0, %xmm1
vfmadd132sd     %xmm2, %xmm1, %xmm0
vsqrtsd %xmm0, %xmm1, %xmm1
```        

