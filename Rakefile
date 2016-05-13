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

def lexer_l_file
  "ext/awasm_native/lexer.l"
end

def lexer_c_file
  lexer_l_file.ext 'c'
end

def lexer_h_file
  lexer_l_file.ext 'h'
end

file lexer_c_file do |t|
  sh "flex --header-file=#{lexer_c_file} --outfile=#{lexer_c_file} #{lexer_l_file}"
end

task :lexer => lexer_c_file

directory 'lib' => ['awasm:gen', :lexer]

task :console do
  sh "pry --gem"
end


