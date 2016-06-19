require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

if have_header('capstone/capstone.h')
  $LDFLAGS << ' -lcapstone'
end

$CFLAGS << " -I#{__dir__}/gen"

$CFLAGS << ' -std=c11 -Wextra -Wall -pedantic -Wno-unused-label -Wuninitialized'\
           ' -Wswitch-default -fstrict-aliasing -Wstrict-aliasing=3 -Wunreachable-code'\
           ' -Wundef -Wpointer-arith -Wwrite-strings -Wconversion -Winit-self -Wno-unused-parameter'

$LDFLAGS << ''

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /clang/
  $CFLAGS << ' -Wno-unknown-warning-option -Wno-parentheses-equality -Wno-error=ignored-attributes'\
             ' -Wno-missing-field-initializers -Wno-missing-braces'
end

if enable_config('debug')
  $CFLAGS << ' -Werror -Wno-error=unused-function'\
             ' -Wno-error=implicit-function-declaration'
  $defs.push('-DEVOASM_MIN_LOG_LEVEL=EVOASM_LOG_LEVEL_DEBUG')
end

create_makefile('evoasm_native')
