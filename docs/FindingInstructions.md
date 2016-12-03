# @title Finding Instructions
# Finding Instructions

*Evoasm* can be used to find instructions that exhibit a certain behavior.
Let's assume we want to find an instruction that counts the number of 1s or the number 
of trailing 0s in a binary number.
Is there an instruction for that? Let's find out.

{include:file:./examples/bit_insts.rb}

Depending on your CPU model this might output the following:

```
popcnt

bsf
```
