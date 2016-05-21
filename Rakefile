require 'bundler/gem_tasks'

require 'rake/testtask'
require 'rake/extensiontask'

require 'awasm/tasks/gen_task'
require 'awasm/tasks/template_task'

Rake::ExtensionTask.new('awasm_native')

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.pattern = "test/**/*_test.rb"
end

Awasm::Tasks::GenTask.new

begin
  require 'awasm/scrapers'
  Awasm::Scrapers::X64.new do |t|
    t.output_filename = Awasm::Gen::Task::X64_TABLE_FILENAME
  end
rescue LoadError
end

def lexer_l_file
  "ext/awasm_native/lexer.l"
end

def lexer_c_file
  lexer_l_file.ext 'c'
end

def lexer_h_file
  lexer_l_file.ext 'h'
end

file lexer_c_file => lexer_l_file do |t|
  sh "flex --header-file=#{lexer_h_file} --outfile=#{lexer_c_file} #{lexer_l_file}"
end

task :lexer => lexer_c_file

directory 'lib' => ['awasm:gen', 'awasm:templates', :lexer]

task :console do
  sh "pry --gem"
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-edge.h.tmpl)
  t.target = %w(awasm-src-edge.h)
  t.subs = {
    t: 'awasm_sym',
    s: 'awasm_src_edge',
    w: 16,
    includes: <<~EOL
      #include "awasm-sym.h"
    EOL
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-node.h.tmpl)
  t.target = %w(awasm-src-node.h)
  t.subs = {
    t: 'awasm_token',
    l: 'token',
    s: 'awasm_src_node',
    w: 16,
    includes: <<~EOL
      #include "awasm-token.h"
    EOL
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-seq.c.tmpl awasm-seq.h.tmpl)
  t.target = %w(awasm-src-edge-list.c awasm-src-edge-list.h)
  t.subs = {
    s: 'awasm_src_edge_list',
    e: 'awasm_src_edge',
    includes: '#include "gen/awasm-src-edge.h"',
    embed: 0,
    w: 16,
    eql: <<~EOL
      return a->dir == b->dir &&
             a->node_idx == b->node_idx &&
             a->label == b->label;
    EOL
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-seq.c.tmpl awasm-seq.h.tmpl)
  t.target = %w(awasm-src-node-list.c awasm-src-node-list.h)
  t.subs = {
    s: 'awasm_src_node_list',
    e: 'awasm_src_node',
    w: 16,
    includes: '#include "awasm-src-node.h"',
    embed: 0,
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-graph.c.tmpl awasm-graph.h.tmpl)
  t.target = %w(awasm-src-graph.c awasm-src-graph.h)
  t.subs = {
    s: 'awasm_src_graph',
    el: 'awasm_src_edge_list',
    nl: 'awasm_src_node_list',
    e: 'awasm_src_edge',
    n: 'awasm_src_node',
    l: 'awasm_sym',
    w: 16,
    includes: <<~END,
      #include "awasm-src-edge-list.h"
      #include "awasm-src-node-list.h"
      #include "awasm-sym.h"
    END
    edge_eql: <<~EOL,
      return a->dir == b->dir &&
             a->node_index == b->node_index &&
             a->index == b->index;
    EOL
    embed: 0,
  }
end

task 'awasm:templates' => Awasm::Tasks::TemplateTask.all
