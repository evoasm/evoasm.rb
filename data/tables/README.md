# X64

The table is automatically scraped from Intel's official instruction set manual.
Errors contained in the manual have been corrected, if spotted.

## Operand Flags

Flag  | Meaning | Example
---- | ------------- | -----------------
`m`  | Considered part of the mnemonic (e.g. for disambiguation) | `AL` in `OR AL, imm8` )
`e`  | Operand is encoded | `NOT rm32` 
`r`  | Operand is read |
`w`  | Operand is written |
`c`  | Operand may be written | destination operand of `CMOV` instructions

## License
[Attribution-ShareAlike 4.0 International](http://creativecommons.org/licenses/by-sa/4.0/)

[![Attribution-ShareAlike 4.0 International](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
