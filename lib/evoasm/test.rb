require 'evoasm'
require 'minitest/reporters'
require 'minitest/autorun'

$LOAD_PATH << File.join(Evoasm.test_dir, 'helpers')
$LOAD_PATH << File.join(Evoasm.test_dir, 'unit')

Minitest::Reporters.use!
