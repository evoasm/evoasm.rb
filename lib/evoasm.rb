require 'evoasm/version'
require 'evoasm/core_ext'

module Evoasm
  def self.root
    File.expand_path File.join(__dir__, '..')
  end

  def self.data
    File.join root, 'data'
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
