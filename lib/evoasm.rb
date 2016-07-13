require 'evoasm/version'
require 'evoasm/core_ext'

module Evoasm
  def self.root_dir
    File.expand_path File.join(__dir__, '..')
  end

  def self.data_dir
    File.join root_dir, 'data'
  end

  def self.examples_dir
    File.join root_dir, 'examples'
  end
end

begin
  require 'evoasm_ext'
rescue LoadError => e
  p e
end

require 'evoasm/search'
require 'evoasm/program'
require 'evoasm/error'
