#! /usr/bin/env ruby


#####################################################
DIR = File.dirname($0)
$: << File.join(DIR, 'lib')


#####################################################
require 'getoptlong'
require 'bio'

require 'tree'
require 'Dir'


#####################################################
NW_UTILS_DIR = "/home-user/sswang/software/phylo/newick-utils-1.6/bin"
NW_CLADE = File.join(NW_UTILS_DIR, 'nw_clade')
NW_PRUNE = File.join(NW_UTILS_DIR, 'nw_prune')
GETALLTIPNAMESFROMNWK = File.join(DIR, 'additional_script', "getAllTipNamesFromNewick.rb")


#####################################################
tree_file = nil
gene_tree_file = nil
outdir = nil
is_force = false
is_tolerate = false

taxa_node_info = Hash.new


#####################################################
def getTaxaNodeInfo(tree)
  arr = Array.new
  tree.nodes.each do |node|
    if node.isTip?(tree)
      taxa = [node.name]
    else
      taxa = tree.tips(node).map{|i|i.name.to_i}.sort
    end
    arr << [taxa]
  end
  return(arr.uniq)
end


#####################################################
if __FILE__ == $0; then
  opts = GetoptLong.new(
    ['-t', '-i', '-s', GetoptLong::REQUIRED_ARGUMENT],
    ['-g', GetoptLong::REQUIRED_ARGUMENT],
    ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
    ['--force', GetoptLong::NO_ARGUMENT],
    ['--tolerate', GetoptLong::NO_ARGUMENT],
  )


  opts.each do |opt, value|
    case opt
      when /^-[tis]$/
        tree_file = value
      when /^-g$/
        gene_tree_file = value
      when /^--outdir$/
        outdir = value
      when /^--force$/
        is_force = true
      when /^--tolerate$/
        is_tolerate = true
    end
  end


  #####################################################
  mkdir_with_force(outdir, is_force, is_tolerate)
  subtree_file = File.join(outdir, "subtree")

  tree = getTreeObjs(tree_file).shift
  gene_tree = getTreeObjs(gene_tree_file).shift


  #####################################################
  gene_tree_tip_names = gene_tree.allTips.map{|tip|tip.name.split(' ')[0]}

  `#{NW_CLADE} #{tree_file} #{gene_tree_tip_names.join(' ')} > #{subtree_file}`
  `sed -i 's/^/(/; s/;$/);/' #{subtree_file}`

  subtree = getTreeObjs(subtree_file).shift

  #tip_names = `ruby #{GETALLTIPNAMESFROMNWK} -i #{subtree_file}`.chomp.split(' ')

  #puts subtree.output_newick.gsub!(/[\n\s]/, '')


  #####################################################
  taxa_node_info['tree'] = getTaxaNodeInfo(tree)
  taxa_node_info['subtree'] = getTaxaNodeInfo(subtree)

  puts taxa_node_info['tree'].size
  puts taxa_node_info['subtree'].size
  diff_set = taxa_node_info['tree'] - taxa_node_info['subtree']


  counts_outfile = File.join(outdir, 'diff.counts')
  out_fh = File.open(counts_outfile, 'w')
  diff_set.each do |taxa|
    out_fh.puts taxa.join('-') + ': 0'
  end
  out_fh.close
end


