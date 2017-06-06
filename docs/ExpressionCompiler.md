# @title Expression Compiler
# Expression Compiler

The following script takes a mathematical expression as a command line argument.
It then evaluates the expression for some specific points to generate example cases.

Then *Evoasm* is used to find a sequence of machine code instructions that match the
example set, which means it calculates the original math expression.

The time it takes to find such a sequence of machine code varies greatly, and sometimes
Evoasm even fails to find one. It also strongly depends on the chosen meta-parameters (kernel size, deme size etc.).
Keep that in mind if you cannot exactly reproduce what is shown below.

{include:file:docs/examples/expr_comp.rb}


Here are some example runs with results (result have introns eliminated):

## Example 1 – x/2.0

```
$ bundle exec ruby docs/examples/expr_comp.rb --use-gem-libevoasm "x/2.0
```

### Result

```
0x7f45ca91a00f:	addps	xmm0, xmm2
0x7f45ca91a012:	movdqa	xmm3, xmm2
0x7f45ca91a016:	vpmaddubsw	xmm1, xmm3, xmm2
0x7f45ca91a01b:	vdivpd	xmm0, xmm1, xmm0
0x7f45ca91a01f:	vdpps	ymm1, ymm0, ymm0, 2
0x7f45ca91a025:	pmaxsw	xmm1, xmm0
Input registers: xmm0:0, xmm2:0
Output registers: xmm1
Average loss is 0.0
Generations: 4338
```

## Example 2 – sqrt(x)

```
$ bundle exec ruby docs/examples/expr_comp.rb --use-gem-libevoasm "sqrt(x)"
```

### Result

```
0x7fbd9c56800f:	pmovsxwd	xmm2, xmm3
0x7fbd9c568014:	cvtsi2sd	xmm2, eax
0x7fbd9c568018:	vsqrtpd	xmm3, xmm2
Input registers: a:0, xmm3:0
Output registers: xmm3
Average loss is 0.0
Generations: 0
```


## Example 3 – sqrt(x**3)

```
$ bundle exec ruby docs/examples/expr_comp.rb --use-gem-libevoasm "sqrt(x**3)"
```

### Result

```
0x7f19a13ef00f:	vphsubw	ymm0, ymm1, ymm3
0x7f19a13ef014:	vfnmsub213ps	ymm2, ymm3, ymm2
0x7f19a13ef019:	pslld	xmm1, xmm3
0x7f19a13ef01d:	vpmuludq	xmm1, xmm2, xmm3
0x7f19a13ef021:	vfmsub231ps	ymm0, ymm1, ymm2
0x7f19a13ef026:	pmullw	xmm2, xmm1
0x7f19a13ef02a:	vcvtdq2pd	ymm3, xmm2
0x7f19a13ef02e:	vmovapd	xmm2, xmm3
0x7f19a13ef032:	vsqrtpd	xmm0, xmm2
Input registers: xmm0:0, xmm1:0, xmm2:0, xmm3:0
Output registers: xmm0
Average loss is 0.0
Generations: 7788
```


## Example 4 – 2*x

```
$ bundle exec ruby docs/examples/expr_comp.rb --use-gem-libevoasm "2*x"
```

### Result

```
0x7faadba0a00f:	vpaddd	ymm0, ymm2, ymm2
0x7faadba0a013:	vcvtdq2pd	xmm1, xmm0
Input registers: xmm2:0
Output registers: xmm1
Average loss is 0.0
Generations: 36
```

## Example 5 – 3*x

```
$ bundle exec ruby docs/examples/expr_comp.rb --use-gem-libevoasm "2*x"
```

### Result

```
0x7fd9c57c400f:	paddusb	xmm2, xmm2
0x7fd9c57c4013:	vpabsb	xmm0, xmm0
0x7fd9c57c4018:	vpaddd	xmm3, xmm0, xmm2
0x7fd9c57c401c:	vmovddup	ymm0, ymm3
0x7fd9c57c4020:	vcvtdq2pd	xmm3, xmm0
Input registers: xmm0:0, xmm2:0, xmm3:0
Output registers: xmm3
Average loss is 0.0
Generations: 120
```

