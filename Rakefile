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
  t.target = %w(awasm-asg-edge.h)
  t.subs = {
    t: 'awasm_sym',
    s: 'awasm_asg_edge',
    w: 32,
    includes: <<~EOL
      #include "awasm-sym.h"
    EOL
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-node.h.tmpl)
  t.target = %w(awasm-asg-node.h)
  t.subs = {
    t: 'awasm_token',
    l: 'token',
    s: 'awasm_asg_node',
    w: 32,
    includes: <<~EOL
      #include "awasm-token.h"
    EOL
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-seq.c.tmpl awasm-seq.h.tmpl)
  t.target = %w(awasm-asg-edge-list.c awasm-asg-edge-list.h)
  t.subs = {
    s: 'awasm_asg_edge_list',
    e: 'awasm_asg_edge',
    includes: '#include "gen/awasm-asg-edge.h"',
    embed: 0,
    w: 32,
    eql: <<~EOL
      return a->dir == b->dir &&
             a->node_idx == b->node_idx &&
             a->label == b->label;
    EOL
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-seq.c.tmpl awasm-seq.h.tmpl)
  t.target = %w(awasm-asg-node-list.c awasm-asg-node-list.h)
  t.subs = {
    s: 'awasm_asg_node_list',
    e: 'awasm_asg_node',
    w: 32,
    includes: '#include "awasm-asg-node.h"',
    embed: 0,
  }
end

Awasm::Tasks::TemplateTask.new do |t|
  t.source = %w(awasm-graph.c.tmpl awasm-graph.h.tmpl)
  t.target = %w(awasm-asg.c awasm-asg.h)
  t.subs = {
    s: 'awasm_asg',
    el: 'awasm_asg_edge_list',
    nl: 'awasm_asg_node_list',
    e: 'awasm_asg_edge',
    n: 'awasm_asg_node',
    l: 'awasm_sym',
    w: 32,
    includes: <<~END,
      #include "awasm-asg-edge-list.h"
      #include "awasm-asg-node-list.h"
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
