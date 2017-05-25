# Evoasm

## Description

*Evoasm* is an AIMGP (*Automatic Induction of Machine code by Genetic Programming*) engine.

You give it a set of examples, that is, several input/output pairs, that describe a program's behavior.
It will then try to come up with a short program (in the form of machine code) that follows your specification,
by means of genetic programming.
*Evoasm* contains a JIT that executes the generated machine code on the fly.

Currently, the only supported architecture is **x86-64**.

## Features

* Fast JIT
* [x86-64](https://github.com/evoasm/evoasm-gen/blob/master/data/tables/x64.csv) up to AVX2 (no FPU)
* Lightweight backend [C library](https://github.com/evoasm/libevoasm) with no third-party dependencies
* Support for floating-point and integer inputs/outputs including SIMD vectors
* Automatically generated and verified instruction encoder
* Parallel island model using OpenMP
* Ruby bindings

## Installation

    $ git clone --recursive https://github.com/evoasm/evoasm
    $ bundle install
    # compile libevoasm, omit --no-omp if your compiler has OpenMP support
    $ bundle exec rake compile -- --no-omp
    $ bundle exec ruby docs/examples/sym_reg.rb # run example

### Requirements

* Ruby (MRI >= 2.3)
* [Capstone](http://www.capstone-engine.org/) for disassembling (*optional*).
* [Gnuplot](http://gnuplot.sourceforge.net) for visualizing loss functions (*optional*)
* POSIX-compliant OS (Linux and Mac OS X should both work).


## Documentation

Please see the [API documentation](https://evoasm.github.io/evoasm/doc/),
have a look at the [examples](https://evoasm.github.io/evoasm/doc/file.SymbolicRegression.html)
or the [test cases](https://github.com/evoasm/evoasm/tree/master/test/integration).


## Contributing

1. Fork it ( https://github.com/furunkel/evoasm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

[AGPL-3.0][license]

[license]: https://github.com/furunkel/evoasm/blob/master/LICENSE.md
