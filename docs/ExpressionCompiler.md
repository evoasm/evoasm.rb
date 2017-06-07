# @title Expression Compiler
# Expression Compiler

The following program takes a mathematical expression as a command line argument.
It then evaluates the expression for some specific points to generate example cases.  
Then *Evoasm* is used to find a sequence of machine code instructions whose input and output matches the
example set, that is one that calculates the expression.

The time it takes to find such a sequence of machine code varies greatly, and sometimes
Evoasm even fails to find one at all. It also strongly depends on the chosen meta-parameters (kernel size, deme size etc.).
Keep that in mind if you cannot exactly reproduce what is shown below.

At the moment, expressions are restricted to a single variable *x*, however, adding support for multiple variables 
would not be too hard to implement.

Given below are some example runs with results (introns have been eliminated).
The code is shown at the very bottom of the page.

The command used was 

```
$ bundle exec ruby docs/examples/expr_comp.rb --use-gem-libevoasm "<expr>"
```

The line `Input registers: <reg>:<index>` gives information about which registers have been initialized with
which argument; *x* being the 0th argument. The remaining arguments are possible constants, appearing in the expression.


## Example 1 – x/2.0

```
0x7f023ca0100f:	vdivpd	xmm2, xmm2, xmm3
Input registers: xmm2:0, xmm3:1
Output registers: xmm2
Average loss is 0.0
Generations: 0
```

## Example 2 – sqrt(x)

```
0x7fd1928fc00f:	vfmadd231ps	xmm1, xmm0, xmm1
0x7fd1928fc014:	vshufpd	xmm3, xmm0, xmm1, 0x4e
0x7fd1928fc019:	vphaddsw	ymm2, ymm3, ymm3
0x7fd1928fc01e:	vsqrtpd	xmm2, xmm0
Input registers: xmm0:0, xmm1:0, xmm3:0
Output registers: xmm2
Average loss is 0.0
Generations: 0
```

## Example 3 – sqrt(x**3)

```
0x7fb54e1ca00f:	sqrtsd	xmm1, xmm0
0x7fb54e1ca013:	movq	xmm3, xmm1
0x7fb54e1ca017:	vfnmadd213pd	xmm1, xmm2, xmm3
0x7fb54e1ca01c:	addsubpd	xmm3, xmm1
Input registers: xmm0:0, xmm1:1, xmm2:0
Output registers: xmm3
Average loss is 0.0
Generations: 1620
```

## Example 4 – 2*x

```
0x7f400818100f:	vpsadbw	ymm2, ymm1, ymm3
0x7f4008181013:	vmpsadbw	xmm3, xmm1, xmm0, 2
0x7f4008181019:	vcvtsi2sd	xmm2, xmm3, eax
0x7f400818101d:	vpsrad	ymm3, ymm3, xmm2
0x7f4008181021:	addpd	xmm2, xmm3
0x7f4008181025:	addsd	xmm1, xmm1
0x7f4008181029:	cvttpd2dq	xmm2, xmm1
Input registers: a:0, xmm0:1, xmm1:0, xmm3:1
Output registers: xmm2
Average loss is 0.0
Generations: 42
```

## Example 5 – 3*x

```
0x7fcd9b73500f:	vpsrad	ymm1, ymm1, xmm1
0x7fcd9b735013:	vmulsd	xmm1, xmm1, xmm1
0x7fcd9b735017:	vfmaddsub213pd	ymm0, ymm3, ymm1
0x7fcd9b73501c:	vcvttpd2dq	xmm3, ymm0
0x7fcd9b735020:	orpd	xmm3, xmm3
Input registers: xmm0:0, xmm1:1, xmm3:1
Output registers: xmm3
Average loss is 0.0
Generations: 90
```

## Example 6 – (3.5*x) + 105.01

```
0x7f9ef260a00f:	vfmsubadd231pd	ymm2, ymm1, ymm0
Input registers: xmm0:0, xmm1:1, xmm2:2
Output registers: xmm2
Average loss is 0.0
Generations: 264
```

## Code

{include:file:docs/examples/expr_comp.rb}
