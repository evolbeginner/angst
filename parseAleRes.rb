#! /usr/bin/env ruby


###############################################################################
DIR = File.dirname($0)
$: << File.join(DIR, 'lib')


###############################################################################
require 'getoptlong'
require 'parallel'
require 'bio'

require 'tree'
require 'Dir'


###############################################################################
infile = nil
infiles = Array.new
indir = nil
species_rela_file = nil
cpu = 1

start_counter = 0
nodeName2Copy = Hash.new
tree0 = nil


###############################################################################
def get_species_rela(infile)
  order2species = Hash.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    species, order = line.split("\t")
    order2species[order] = species
  end
  in_fh.close
  return(order2species)
end


###############################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--species_rela', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--indir'
      indir = value
    when '--species_rela'
      species_rela_file = value
    when '--cpu'
      cpu = value.to_i
  end
end


###############################################################################
order2species = get_species_rela(species_rela_file)


###############################################################################
subdirs = read_infiles(indir)
subdirs.each do |subdir|
  b = File.basename(subdir)
  infile = File.join(subdir, b+'.bootstrap.trees.ale.uml_rec')
  if File.exists?(infile)
    infiles << infile
  end
end

#infiles = infiles[0,10]

###############################################################################
results = Parallel.map(infiles, in_processes: cpu) do |infile|
  tree = nil
  nodeName2Copy = Hash.new

  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    if line =~ /^S:\t(.+)/
      tree = getTreeObjFromNwkString($1)
    end
    if line =~ /^\# of	 Duplications	Transfers	Losses	Originations	copies/
      start_counter += 1
      next
    end
    if start_counter
      #S_terminal_branch	1	0	0.02	0.02	0	0
      line_arr = line.split("\t")
      node_name = line_arr[1]
      copies = line_arr[-1].to_f
      nodeName2Copy[node_name] = copies >= 0.5 ? 1 : 0
      #nodeName2Copy[node_name] = copies
    end
  end
  in_fh.close

  tree.nodes.each do |node|
    node.name = node.bootstrap_string if not node.isTip?(tree)
    #node.bootstrap = nodeName2Copy[node.name]
    node.bootstrap = nil if node.isTip?(tree)
  end

  [tree, nodeName2Copy]
end


###############################################################################
res_1 = results.shift
tree0, nodeName2Copy = res_1

tree0.nodes.each do |node|
  node.bootstrap = nodeName2Copy[node.name]
end

results.each do |tree, nodeName2Copy|
  tree0.nodes.each do |node|
    #node.name = node.bootstrap if not node.isTip?(tree0)
    node.bootstrap += nodeName2Copy[node.name]
    #node.name = node.isTip?(tree) ? [node.bootstrap.to_i, node.name].join('|') : nil
    #node.bootstrap = nil if node.isTip?(tree)
  end
end


###############################################################################
tree0.nodes.each do |node|
  node.name = order2species[node.name] if order2species.include?(node.name)
  node.name = node.isTip?(tree0) ? [node.bootstrap.to_i, node.name].join('|') : nil
  node.bootstrap = nil if node.isTip?(tree0)
end

puts tree0.cleanNewick


