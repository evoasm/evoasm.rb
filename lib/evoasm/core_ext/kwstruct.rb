# The MIT License (MIT)
# Copyright (c) 2015 Maxim Chernyak
class KwStruct < Struct
  def self.new(*members, &block)
    super.tap do |struct_class|
      struct_class.class_eval <<-RUBY
        def initialize(#{members.map { |m| "#{m}: nil" }.join(', ')})
          super(#{members.join(', ')})
        end
      RUBY
    end
  end
end
