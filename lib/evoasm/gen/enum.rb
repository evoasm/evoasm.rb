require 'evoasm/gen/strio'
require 'evoasm/gen/name_util'

module Evoasm
  module Gen
    class Enum
      include NameUtil

      attr_reader :name, :flags
      alias_method :flags?, :flags

      def initialize(name = nil, elems = [], prefix: nil, flags: false)
        @name = name
        @prefix = prefix
        @map = {}
        @counter = 0
        @flags = flags
        add_all elems
      end

      def n
        @counter
      end

      def to_c(io = StrIO.new, typedef: true)
        raise 'name missing' if !name

        type_name = c_type_name

        io.puts "#{typedef ? 'typedef ' : ''}enum #{type_name} {"
        io.indent do
          each do |elem, value|
            elem_name = elem_name_to_c elem
            c_value =
              if valid_elem?(value)
                elem_name_to_c value
              else
                if flags?
                  "1 << #{value}"
                else
                  "#{value}"
                end
              end
            io.puts "#{elem_name} = #{c_value},"
          end
          if !flags?
            io.puts n_elem_to_c
          end
        end
        io.write '}'
        io.write " #{type_name}" if typedef
        io.puts ';'
        unless flags?
          io.puts "#define #{bits_const_name_to_c} #{Math.log2(max).ceil.to_i}"
        end

        io.string
      end

      def max
        @map.each_with_index.inject(0) do |acc, (index, (k, v))|
          if v
            [v + 1, acc + 1].max
          else
            acc + 1
          end
        end - 1
      end

      def c_type(typedef = false)
        "#{typedef ? '' : 'enum '}#{c_type_name}"
      end

      def c_type_name
        name_to_c name, @prefix
      end

      def bits_const_name_to_c
        name_to_c "#{prefix_name}_bits", @prefix, const: true
      end

      def n_elem_to_c
        name_to_c "n_#{prefix_name}s", @prefix, const: true
      end

      def keys
        @map.keys
      end

      def add(elem, alias_elem = nil)
        fail ArgumentError, 'can only add symbols or strings' \
          unless valid_elem?(elem) && (!alias_elem || valid_elem?(alias_elem))

        return if @map.key? elem

        value = alias_elem || @counter
        @counter += 1 if alias_elem.nil?

        @map[elem] = value
      end

      def add_all(elems)
        elems.each do |elem|
          add elem
        end
      end

      def each(&block)
        return to_enum(:each) if block.nil?
        @map.each_key do |k|
          block[k, self[k]]
        end
      end

      def alias(key)
        key = @map[key]
        case key
        when Symbol, String
          key
        else
          nil
        end
      end

      def [](elem)
        value = @map[elem]

        if @map.key? value
          @map.fetch value
        else
          value
        end
      end

      private
      def prefix_name
        name.to_s.sub(/_id$/, '')
      end

      def elem_name_to_c(elem_name)
        # convention: _id does not appear in element's name
        name_to_c elem_name, Array(@prefix) + [prefix_name], const: true
      end

      def valid_elem?(elem)
        elem.is_a?(Symbol) || elem.is_a?(String)
      end
    end
  end
end
