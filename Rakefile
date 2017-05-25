require 'bundler/gem_tasks'
require 'rake/testtask'


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


begin
  require 'evoasm/gen'
  Evoasm::Gen::GenTask.new 'lib/evoasm/libevoasm' do |t|
    t.file_types = %i(ruby_ffi)
  end
rescue LoadError => e
  puts "Generator tasks disabled (#{e})"
end

begin
  require 'evoasm/scrapers'
  Evoasm::Scrapers::X64.new do |t|
    t.output_filename = Evoasm::Tasks::GenTask::X64_TABLE_FILENAME
  end
rescue LoadError => e
  puts "Scraper tasks disabled (#{e})"
end

begin
  require 'yard'
  namespace :yard do
    YARD::Rake::YardocTask.new :build do |t|
      t.files = %w(lib/**/*.rb - docs/**/*.md)
      t.options = %w(--asset docs/examples:examples)
    end

    desc "Push YARD documentation to GitHub Pages"
    task :push => :build do
      tmp_dir = Dir.mktmpdir
      cp_r 'doc', tmp_dir
      sh 'git checkout gh-pages'
      rm_r 'doc'
      mv File.join(tmp_dir, 'doc'), 'doc'
      sh 'git add "doc/*"'
      sh 'git commit -m "Update documentation"'
      sh 'git push origin gh-pages'
      sh 'git checkout master'
      remove_entry tmp_dir
    end

  end
rescue LoadError => e
  puts "YARD tasks disabled (#{e})"
end


