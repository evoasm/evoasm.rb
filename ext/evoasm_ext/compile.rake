require 'rake/clean'
require 'ffi'

SHARED_LIB = File.join(__dir__, FFI.map_library_name('evoasm'))
SRC_FILES = FileList[File.join __dir__, 'libevoasm/src/**/*.[ch]']
C_FILES = SRC_FILES.clone.exclude(/\.h$/)
CC = ENV['cc'] || 'cc'
INC_FLAGS = %w(libevoasm/src libevoasm/src/gen).map { |dir| "-I#{File.join __dir__, dir}"}.join ' '

CLEAN.include(SHARED_LIB)

desc "Compile shared library"
task :compile => [SHARED_LIB]
file SHARED_LIB => SRC_FILES do |t|
  sh "#{CC} -shared -g -fPIC #{C_FILES.join(' ')} #{INC_FLAGS} -o #{SHARED_LIB}"
end
