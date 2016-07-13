require 'bundler/gem_tasks'

require 'rake/testtask'
require 'rake/extensiontask'

require 'evoasm/tasks/gen_task'
require 'evoasm/tasks/template_task'

Rake::ExtensionTask.new('evoasm_ext')

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.pattern = "test/**/*_test.rb"
end

Evoasm::Tasks::GenTask.new

begin
  require 'evoasm/scrapers'
  Evoasm::Scrapers::X64.new do |t|
    t.output_filename = Evoasm::Tasks::GenTask::X64_TABLE_FILENAME
  end
rescue LoadError
end

directory 'lib' => ['evoasm:gen', 'evoasm:templates']

task :console do
  sh "pry --gem"
end

=begin
Evoasm::Tasks::TemplateTask.new do |t|
  t.source = %w(evoasm-edge.h.tmpl)
  t.target = %w(evoasm-asg-edge.h)
  t.subs = {
    t: 'evoasm_sym',
    s: 'evoasm_asg_edge',
    w: 32,
    includes: <<~EOL
      #include "evoasm-sym.h"
    EOL
  }
end

Evoasm::Tasks::TemplateTask.new do |t|
  t.source = %w(evoasm-node.h.tmpl)
  t.target = %w(evoasm-asg-node.h)
  t.subs = {
    t: 'evoasm_token',
    l: 'token',
    s: 'evoasm_asg_node',
    w: 32,
    includes: <<~EOL
      #include "evoasm-token.h"
    EOL
  }
end

Evoasm::Tasks::TemplateTask.new do |t|
  t.source = %w(evoasm-free-list.c.tmpl evoasm-free-list.h.tmpl)
  t.target = %w(evoasm-asg-edge-list.c evoasm-asg-edge-list.h)
  t.subs = {
    s: 'evoasm_asg_edge_list',
    e: 'evoasm_asg_edge',
    includes: '#include "gen/evoasm-asg-edge.h"',
    embed: 0,
    w: 32,
    eql: <<~EOL
      return a->dir == b->dir &&
             a->node_idx == b->node_idx &&
             a->label == b->label;
    EOL
  }
end

Evoasm::Tasks::TemplateTask.new do |t|
  t.source = %w(evoasm-free-list.c.tmpl evoasm-free-list.h.tmpl)
  t.target = %w(evoasm-asg-node-list.c evoasm-asg-node-list.h)
  t.subs = {
    s: 'evoasm_asg_node_list',
    e: 'evoasm_asg_node',
    w: 32,
    includes: '#include "evoasm-asg-node.h"',
    embed: 0,
  }
end

Evoasm::Tasks::TemplateTask.new do |t|
  t.source = %w(evoasm-graph.c.tmpl evoasm-graph.h.tmpl)
  t.target = %w(evoasm-asg.c evoasm-asg.h)
  t.subs = {
    s: 'evoasm_asg',
    el: 'evoasm_asg_edge_list',
    nl: 'evoasm_asg_node_list',
    e: 'evoasm_asg_edge',
    n: 'evoasm_asg_node',
    l: 'evoasm_sym',
    w: 32,
    includes: <<~END,
      #include "evoasm-asg-edge-list.h"
      #include "evoasm-asg-node-list.h"
      #include "evoasm-sym.h"
    END
    edge_eql: <<~EOL,
      return a->dir == b->dir &&
             a->node_index == b->node_index &&
             a->index == b->index;
    EOL
    embed: 0,
  }
end

Evoasm::Tasks::TemplateTask.new do |t|
  t.source = %w(evoasm-free-list.c.tmpl evoasm-free-list.h.tmpl)
  t.target = %w(evoasm-page-list.c evoasm-page-list.h)
  t.subs = {
    s: 'evoasm_page_list',
    e: 'evoasm_page',
    w: 32,
    includes: '#include "evoasm-page.h"',
    embed: 0,
  }
end

=end

task 'evoasm:templates' => Evoasm::Tasks::TemplateTask.all

task :default => :test
