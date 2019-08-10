#! /usr/bin/env ruby


##########################################################
dir = File.dirname($0)
$: << File.join(dir, 'lib')


##########################################################
require 'getoptlong'
require 'bio'

require 'tree'


##########################################################
infile = nil


##########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
  end
end


##########################################################
tree = getTreeObjs(infile).shift()

#a_node = tree.nodes.select{|node|node.name == '1'}.shift
haha = %w[90 94 95]
a_nodes = tree.nodes.select{|node|haha.include? node.name}

p a_nodes.size
lca = a_nodes.inject(lca=a_nodes[0]){|lca, node|tree.lowest_common_ancestor(node, lca)}
subtree = tree.subtree_with_all_paths(tree.descendents(lca))
subtree.options[:bootstrap_style] = :disabled
puts subtree.output_newick.gsub(/[\n\s]/, '')
exit

tree.nodes.each do |node|
  p node.name
  p node
  lca = tree.lowest_common_ancestor(a_node, node)
  subtree = tree.subtree_with_all_paths(tree.descendents(lca))
  subtree.options[:bootstrap_style] = :disabled
  p subtree.output_newick.gsub(/[\n\s]/, '')
  puts
end


