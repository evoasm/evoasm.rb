# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'evoasm/version'

Gem::Specification.new do |spec|
  spec.name          = 'evoasm'
  spec.version       = Evoasm::VERSION
  spec.authors       = ['Julian Aron Prenner (furunkel)']
  spec.email         = ['furunkel@polyadic.com']
  spec.summary       = %q{An AIMGP engine}
  spec.description   = %q{An AIMGP (Automatic Induction of Machine code by Genetic Programming) engine}
  spec.homepage      = 'https://github.com/evoasm/evoasm/'
  spec.license       = 'AGPL-3.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.files        += Dir['ext/evoasm_ext/**/*.[ch]']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.extensions    = %w(ext/evoasm_ext/Rakefile)

  spec.add_dependency 'pastel', '~> 0.6'
  spec.add_dependency 'ffi', '~> 1.9'
  spec.add_dependency 'gv', '~> 0.1'
  spec.add_dependency 'haml', '~> 4.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.41'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1'
end
