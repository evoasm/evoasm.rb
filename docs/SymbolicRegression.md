# @title Symbolic Regression
# Symbolic Regression

A classical application of genetic programming is [symbolic regression](https://en.wikipedia.org/wiki/Symbolic_regression).
Symbolic regression is the task of finding a mathematical expression that approximates a given set of data points as closely as possible.

## Example Data

For purposes of illustration, assume we are given the following
table of data points, sampled from the function
<math xmlns='http://www.w3.org/1998/Math/MathML'>
  <mi>y</mi>
  <mo>=</mo>
  <msqrt>
    <msup>
      <mi>x</mi>
      <mn>3</mn>
    </msup>
    <mo>+</mo>
    <mrow>
      <mn>2</mn>
      <mi>x</mi>
    </mrow>
  </msqrt>
</math>.

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
to come up with a program that, given *x*, will output the corresponding
*y* for all *x* (i.e. not only those listed in the table).

## Finding a Solution Program

Here is how it is done:
 
{include:file:docs/examples/sym_reg.rb}

On my machine, *Evoasm* will find a solution in less than a second:

```
0x555556b9e270:	vmulsd	xmm2, xmm0, xmm2
0x555556b9e274:	vfmadd213sd	xmm2, xmm1, xmm0
0x555556b9e279:	vaddsd	xmm3, xmm3, xmm2
0x555556b9e27d:	vfnmadd231sd	xmm2, xmm2, xmm2
0x555556b9e282:	vfnmadd231sd	xmm0, xmm1, xmm0
0x555556b9e287:	vfmadd132sd	xmm0, xmm0, xmm0
0x555556b9e28c:	vsqrtsd	xmm1, xmm1, xmm3
0x555556b9e290:	addsd	xmm0, xmm2
0x555556b9e294:	vaddsd	xmm3, xmm3, xmm2
0x555556b9e298:	vmulsd	xmm0, xmm2, xmm2
```

## Examining the Solution
You can now experiment with the found program.
Use the {Evoasm::Kernel#run Kernel#run} method to run the found program with arbitrary input.

```ruby
program.run 1.0  # => [1.7320508075688772]
# test for values not given in table
program.run 10.0 # => [31.937438845342623]
```

## Intron Elimination
The solutions found by *Evoasm* will usually contain large 
portions of noneffective code (so-called introns).

Introns can be removed using the `eliminate_introns!` method.
This will considerably shorten the size of the solution:

```ruby
program.eliminate_introns.disassembly format: true
```
gives

```
0x555556ba59f0:	vmulsd	xmm2, xmm0, xmm2
0x555556ba59f4:	vfmadd213sd	xmm2, xmm1, xmm0
0x555556ba59f9:	vaddsd	xmm3, xmm3, xmm2
0x555556ba59fd:	vsqrtsd	xmm1, xmm1, xmm3
```

For comparison, here is what GCC 7 outputs with `-O3 -march=core-avx2 -ffast-math`
```
        vmovapd xmm1, xmm0
        vfmadd213sd xmm1, xmm0, QWORD PTR .LC0[rip]
        vmulsd  xmm0, xmm1, xmm0
        vsqrtsd xmm0, xmm0, xmm0

.LC0:
        .long   0
        .long   1073741824
```        

