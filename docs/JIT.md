# @title Just-in-time Compilation
# Just-in-time Compilation

Using *Evoasm*'s {Evoasm::Buffer Buffer} class, it is possible to do simple just-in-time compilation.

{include:file:docs/examples/jit.rb}

The second block executes a division-by-zero, causing an exception to be thrown.
The expected output is thus:

```
Result: 3
Execution failed with exception `de'
```
