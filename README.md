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
* Non-linear control flow
* [x86-64](https://github.com/evoasm/evoasm-gen/blob/master/data/tables/x64.csv) up to AVX2 (no FPU)
* Lightweight backend [C library](https://github.com/evoasm/libevoasm) with no third-party dependencies
* Ruby bindings

## Installation

    $ gem install evoasm
    
### Requirements

* Ruby (MRI >= 2.3, JRuby >= 9.1.2)
* [Capstone](http://www.capstone-engine.org/) for disassembling (*optional*).
* [Graphviz](http://www.graphviz.org/) (libgraphviz) for visualizing programs (*optional*).
* POSIX-compliant OS (Linux and Mac OS X should both work).

## Usage

Please see [Getting Started](https://github.com/evoasm/evoasm/blob/master/docs/GettingStarted.md).


## Contributing

1. Fork it ( https://github.com/furunkel/evoasm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

[AGPL-3.0][license]

[license]: https://github.com/furunkel/evoasm/blob/master/LICENSE.md
