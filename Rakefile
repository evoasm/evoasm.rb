require 'bundler/gem_tasks'
require 'rake/testtask'

require 'evoasm/gen'

import 'ext/evoasm_ext/compile.rake'


namespace :test do
  Rake::TestTask.new :unit do |t|
    t.libs.push 'lib', 'test/unit', 'test/helpers'
    t.pattern = "test/unit/**/*_test.rb"
    t.verbose = true
  end

  Rake::TestTask.new :integration do |t|
    t.libs.push 'lib', 'test/integration', 'test/helpers'
    t.pattern = "test/integration/**/*_test.rb"
    t.verbose = true
  end
end

task :test => ['test:unit', 'test:integration']
task :default => :test


require 'evoasm/gen'
Evoasm::Gen::GenTask.new 'lib/evoasm/libevoasm' do |t|
  t.file_types = %i(ruby_ffi)
end

begin
  require 'evoasm/scrapers'
  Evoasm::Scrapers::X64.new do |t|
    t.output_filename = Evoasm::Tasks::GenTask::X64_TABLE_FILENAME
  end
rescue LoadError
end

