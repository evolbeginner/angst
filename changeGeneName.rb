#! /usr/bin/env ruby


#########################################################
dir = File.dirname($0)
$: << File.join(dir, 'lib')


#########################################################
require 'getoptlong'

require 'tree'
require 'util'


#########################################################
out2in_files = ["~/project/Rhizobiales/data/genome_source/out2in.tbl", "~/project/Rhizobiales/data/genome_source/out2in-outgroup.tbl"].map{|i|File.expand_path(i)}


#########################################################
treefile = nil
numberOfTrees = 10000


#########################################################
def outputTree(gene_tree)
  output = gene_tree.output_newick
  output.gsub!(/[\n\s']/, '')
  puts output
end


#########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-n', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      treefile = value
    when /^-n$/
      numberOfTrees = value.to_i
  end
end


#########################################################
$out2in, $in2out = getSpeciesNameRela(out2in_files)

trees = getTreeObjs(treefile, numberOfTrees)

trees.each do |tree|
  tree.each_node do |node|
    if node.isTip?(tree)
      arr = node.name.split(/[ ]/)
      num = 2
      if node.name =~ /^Agrobacterium fabrum str C58/
        num = 1
      else
        num = 2
      end
      gene = arr.pop(num).join('_')
      taxon = $in2out[arr.join('_')]
      node.name = [taxon, gene].join('|')
    end
  end
  outputTree(tree)
end


