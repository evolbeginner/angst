#! /usr/bin/env ruby


##########################################################
$: << File.join(File.dirname($0), 'lib')


##########################################################
require 'getoptlong'
require 'bio'

require 'tree'


##########################################################
species_tree_file = nil
gene_tree_file = nil
is_output_species_tree = false


taxa = Array.new
taxon2order = Hash.new
counter_info = Hash.new{|h,k|h[k]=0}


##########################################################
def outputTree(gene_tree)
  output = gene_tree.output_newick
  output.gsub!(/[\n\s']/, '')
  puts output
end


##########################################################
opts = GetoptLong.new(
  ['-s', GetoptLong::REQUIRED_ARGUMENT],
  ['-g', GetoptLong::REQUIRED_ARGUMENT],
  ['--output_species_tree', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-s$/
      species_tree_file = value
    when /^-g$/
      gene_tree_file = value
    when /^--output_species_tree/
      is_output_species_tree = true
  end
end


##########################################################
species_tree = getTreeObjs(species_tree_file).shift
species_tree.each_node do |node|
  if node.isTip?(species_tree)
    taxa << node.name.gsub!(' ', '_')
  end
end


taxa.each do |taxon|
  taxon2order[taxon] = (taxa.index(taxon)+1).to_s
end


if is_output_species_tree
  species_tree.each_node do |node|
    next unless node.isTip?(species_tree)
    puts [node.name, taxon2order[node.name]].join("\t")
    node.name = taxon2order[node.name].to_s
  end
  outputTree(species_tree)
  exit 0
end


##########################################################
gene_trees = getTreeObjs(gene_tree_file)
gene_trees.each do |gene_tree|
  counter_info = Hash.new{|h,k|h[k]=0}
  gene_tree.each_node do |node|
    if node.isTip?(gene_tree)
      taxon = node.name.split('|')[0]
      taxon = taxon.gsub(' ', '_')
      counter_info[taxon2order[taxon]] += 1
      counter = counter_info[taxon2order[taxon]]
      if not taxon2order.include?(taxon)
        STDERR.puts node.name
        STDERR.puts "Fatal error! #{taxon} from #{gene_tree_file} does not exist in the species tree #{species_tree_file}. Exiting ......"
        exit 1
      end
      node.name = [taxon2order[taxon], counter].join('_')
    end
  end
  outputTree(gene_tree)
end


