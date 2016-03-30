require 'bundler/gem_tasks'

require 'rake/testtask'
require 'rake/extensiontask'

require 'awasm/gen/task'

Rake::ExtensionTask.new('awasm_native')

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.pattern = "test/**/*_test.rb"
end

Awasm::Gen::Task.new

begin
  require 'awasm/scrapers'
  Awasm::Scrapers::X64.new do |t|
    t.output_filename = Awasm::Gen::Task::X64_TABLE_FILENAME
  end
rescue LoadError
end

directory 'lib' => 'awasm:gen'

task :console do
  sh "pry --gem"
end


