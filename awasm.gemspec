# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'awasm/version'

Gem::Specification.new do |spec|
  spec.name          = "awasm"
  spec.version       = Awasm::VERSION
  spec.authors       = ["Julian Aron Prenner (furunkel)"]
  spec.email         = ["furunkel@polyadic.com"]
  spec.summary       = %q{A runtime assembler}
  spec.homepage      = ""
  spec.license       = "MPL 2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "pry"
  spec.add_dependency "tty"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler", "~> 0.9"
  spec.add_development_dependency 'erubis', '~> 2.6'
  spec.add_development_dependency "gv"
  spec.add_development_dependency "minitest"
end
