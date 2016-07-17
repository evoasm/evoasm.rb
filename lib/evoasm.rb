require 'evoasm/version'

module Evoasm
  def self.root_dir
    File.expand_path File.join(__dir__, '..')
  end

  def self.data_dir
    File.join root_dir, 'data'
  end

  def self.ext_dir
    File.join root_dir, 'ext'
  end

  def self.examples_dir
    File.join root_dir, 'examples'
  end
end

require 'evoasm/libevoasm'
require 'evoasm/error'

Evoasm::Libevoasm.init(0, FFI::Pointer::NULL, FFI::Pointer::NULL)
