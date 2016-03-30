require 'awasm/version'
require 'awasm/core_ext'

module Awasm
  def self.root
    File.expand_path File.join(__dir__, '..')
  end

  def self.data
    File.join root, 'data'
  end
end

begin
  require 'awasm_native'
rescue LoadError => e
  p e
end

require 'awasm/search'
require 'awasm/program'
require 'awasm/error'
