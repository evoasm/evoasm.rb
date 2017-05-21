require 'rake/clean'
require 'ffi'

SHARED_LIB = File.join(__dir__, FFI.map_library_name('evoasm'))
SRC_FILES = FileList[File.join __dir__, 'libevoasm/src/**/*.[ch]']
C_FILES = SRC_FILES.clone.exclude(/\.h$/).join(' ')
CC = ENV['cc'] || 'cc'
INC_FLAGS = %w(libevoasm/src).map { |dir| "-I#{File.join __dir__, dir}"}.join ' '

DEFS = ''
CFLAGS = ''

if ARGV.include?('--debug')
  DEFS << ' -DEVOASM_LOG_LEVEL=EVOASM_LOG_LEVEL_DEBUG'
  CFLAGS << ' -ggdb3 -O0'
else
  DEFS << ' -DNDEBUG'
  CFLAGS << ' -O3 -g -march=native'
end

if ARGV.include?('--paranoid')
  DEFS << ' -DEVOASM_ENABLE_PARANOID_MODE'
end

unless ARGV.include?('--no-omp')
  CFLAGS << ' -fopenmp'
end

CLEAN.include(SHARED_LIB)

desc "Compile shared library"
task :compile => [SHARED_LIB]
file SHARED_LIB => SRC_FILES do |t|
  sh "#{CC} -shared -fPIC #{CFLAGS} #{DEFS} #{C_FILES} #{INC_FLAGS} -o #{SHARED_LIB}"
end
