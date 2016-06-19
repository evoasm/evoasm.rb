require 'set'

module Evoasm::Gen
  State = Struct.new(:children, :actions, :ret, :_local_params) do
    attr_accessor :id, :comment, :parents

    def initialize
      self.children = []
      self.parents = []
      self.actions = []
      self._local_params = []
    end

    def local_params
      child_local_params = children.map do |child, _, _|
        child.local_params
      end
      all_local_params = (_local_params + child_local_params)
      all_local_params.flatten!
      all_local_params.uniq!

      all_local_params
    end

    def add_local_param(param)
      if param.to_s[0] != '_'
        fail ArgumentError, 'params must start with underscore'
      end

      _local_params << param unless _local_params.include? param
    end

    protected def add_parent(parent)
      parents << parent unless parents.include? parent
    end

    def add_child(child, cond = nil, priority)
      child.add_parent self
      children << [child, cond, priority]
    end

    %i(sets asserts calls writes debugs).each do |name|
      action_name = name.to_s[0..-2].to_sym
      define_method name do
        actions.select { |action, _| action == action_name }
        .map { |_, args| args }
      end
    end

    private def roots
      return [self] if parents.empty?
      parents.flat_map(&:roots)
    end

    def root
      roots = roots()
      fail 'multiple roots' if roots.size > 1
      roots.first
    end

    def empty?
      actions.empty?
    end

    def terminal?
      children.empty?
    end

    def ret?
      ret != nil
    end

    def to_gv
      require 'gv'

      graph = GV::Graph.open 'ast'
      graph[:ranksep] = 1.5
      graph[:statesep] = 0.8
      __to_gv__ graph
      graph
    end

    def __to_gv__(graph, gv_parent = nil, cond = nil, attrs = {}, index = nil, seen = {})
      if seen.key?(self)
        # return
      else
        seen[self] = true
      end

      edge_label = ''
      state_label = ''

      if cond
        if cond.first == :else
          edge_label << "<b> else</b><br></br>\n"
        else
          edge_label << "<b> if</b> #{expr_to_s cond}<br></br>\n"
        end
      end

      if attrs
        attrs.each do |name, value|
          edge_label << "<b> #{name}</b>: #{value}<br></br>\n"
        end
      end

      actions.each do |name, args|
        state_label << send(:"label_#{name}", *args)
      end

      state_label << "<i>#{comment}</i>\n" if comment

      gv_state = graph.node object_id.to_s,
                            shape: (self.ret? ? :house : (state_label.empty? ? :point : :box)),
                            label: graph.html(state_label)

      children.each_with_index do |(child, cond, attrs), index|
        child.__to_gv__(graph, gv_state, cond, attrs, index, seen)
      end

      if gv_parent
        graph.edge gv_parent.name + '.' + gv_state.name + index.to_s,
                   gv_parent, gv_state,
                   label: graph.html(edge_label)
      end

      graph
    end

    private

    def label_set(name, value, _options = {})
      "<b>set</b> #{name} := #{expr_to_s value}<br></br>"
    end

    def label_assert(cond)
      "<b>assert</b> #{expr_to_s cond}<br></br>"
    end

    def label_call(name)
      "<b>call</b> #{name}<br></br>"
    end

    def label_debug(_format, *_args)
      ''
    end

    def label_write(value, size)
      label =
        if value.is_a?(Integer) && size.is_a?(Integer)
          if size == 8
            'x%x' % value
          else
            "b%0#{size}b" % value
          end
        elsif size.is_a? Array
          Array(value).zip(Array(size)).map do |v, s|
            "#{expr_to_s v} [#{expr_to_s s}]"
          end.join ', '
        else
          "#{expr_to_s value} [#{expr_to_s size}]"
        end
      "<b>output</b> #{label}<br></br>"
    end

    def expr_to_s(pred)
      case pred
      when Array
        pred, *args = *pred
        "#{pred}(#{args.map { |a| expr_to_s(a) }.join(', ')})"
      else
        pred
      end
    end
  end
end
