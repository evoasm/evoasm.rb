# Awasm

## Description

*Awasm* is an AIMGP (*Automatic Induction of Machine code by Genetic Programming*) engine.

You give it a set of examples, that is, several input/output pairs, that describe the a program's behavior.
It will then, try to come up with a short program (in the form of machine code) that follows your specification,
by means of genetic programming.
Currently, the only supported architecture is **x86_64**.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'awasm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install awasm --pre

## Usage

Please see [Getting Started](https://github.com/furunkel/awasm/wiki/Getting-Started).


## Contributing

1. Fork it ( https://github.com/furunkel/awasm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

[MPL 2][license]

[license]: https://github.com/furunkel/awasm/blob/master/LICENSE.txt
