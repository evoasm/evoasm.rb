# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'awasm/version'

Gem::Specification.new do |spec|
  spec.name          = "awasm"
  spec.version       = Awasm::VERSION
  spec.authors       = ["Julian Aron Prenner (furunkel)"]
  spec.email         = ["furunkel@polyadic.com"]
  spec.summary       = %q{An AIMGP (Automatic Induction of Machine code by Genetic Programming) engine}
  spec.homepage      = "https://github.com/furunkel/awasm/"
  spec.license       = "MPL-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "pry", "~> 0.10"
  spec.add_dependency "tty", "~> 0.4"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler", "~> 0.9"
  spec.add_development_dependency 'erubis', '~> 2.6'
  spec.add_development_dependency "minitest", "~> 5.8"
end
