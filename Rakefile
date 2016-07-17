require 'bundler/gem_tasks'
require 'rake/testtask'

require 'evoasm/gen'

import 'ext/evoasm_ext/compile.rake'

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.pattern = "test/**/*_test.rb"
end
task :default => :test

require 'evoasm/gen'
Evoasm::Gen::GenTask.new 'lib/evoasm/libevoasm' do |t|
  t.output_formats = %i(ruby_ffi)
end

begin
  require 'evoasm/scrapers'
  Evoasm::Scrapers::X64.new do |t|
    t.output_filename = Evoasm::Tasks::GenTask::X64_TABLE_FILENAME
  end
rescue LoadError
end

