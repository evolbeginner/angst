#! /usr/bin/env ruby


###################################################################
$: <<  File.expand_path("~/project/Rhizobiales/scripts/angst/")
$: <<  File.expand_path("~/project/Rhizobiales/scripts/angst/", 'lib')


###################################################################
require 'getoptlong'
require 'bio'
require 'parallel'

require 'chang_yong'
require 'Dir'
require 'getSubtree'
require 'tree'


###################################################################
infile = nil
outdir = nil
treefiles_arr = Array.new
tree_indirs = Array.new
general_tree_indir = nil
species_tree_file = nil
is_output_species_tree = false
fam_list_file = nil
cpu = 1
is_force = false
is_tolerate = false
$is_angst = false

fams_included = Hash.new
taxa2fam = Hash.new{|h,k|h[k]={}}
fam2taxa = Hash.new{|h,k|h[k]={}}
fam2tips = Hash.new{|h,k|h[k]={}}
lines = Array.new


###################################################################
def getSubRoots(treefiles_arr)
  taxa_includeds = Array.new
  o2c = Hash.new

  treefiles_arr.each_with_index do |treefiles, index|
    taxa_included = Array.new
    treefiles.each do |treefile|
      tree = getTreeObjs(treefile, 1).shift()
      taxa = getSortedTaxa(tree.tips(tree.root), true, true, false)
      taxa_included << taxa
    end
    taxa_includeds << taxa_included
    o2c[index] = File.basename(File.dirname(treefiles[0]))
  end

  return([taxa_includeds, o2c])
end


def getSortedTaxa(tips, is_space=true, is_remove_front_num=true, is_remove_end_num=true)
  tips = Marshal.load(Marshal.dump(tips))
  if is_space
    tips.map{|i|i.name.gsub!(' ', '_'); i.name}
  end
  if is_remove_front_num
    tips.map{|i|i.name.sub!(/^\d+\|/,''); i.name}
  end
  if is_remove_end_num
    tips.map{|i|i.name.sub!(/_\d+$/,''); i.name}
  end
  #tips.sort_by!{|i|i.name}.map!{|i|i.name}
  tips.sort_by{|i|i.name}.map{|i|i.name}
  return(tips)
end


def getLines(infile)
  lines = Array.new
  in_fh = File.open(infile, 'r')
  is_reading_fam = false
  in_fh.each_line do |line|
    line.chomp!
    #break if lines.size >= 600
    is_reading_fam = true and next if line =~ /^\t\t#Family	Ancestral Family Size Tree$/
    is_reading_fam = false if line =~ /^\t\tTotal Ancestral Size/
    next unless is_reading_fam
    lines << line
  end
  in_fh.close
  return(lines)
end


def parse_general_tree_indir(indir, treefiles_arr)
  subdirs = read_infiles(indir)
  subdirs.delete_if{|i| not File.exists?(File.join(i,'F.tre')) or not File.exists?(File.join(i,'NF.tre')) }
  treefiles_arr.concat(subdirs.map{|i| [File.join(i,'F.tre'), File.join(i,'NF.tre')] })
  return(treefiles_arr)  
end


def parse_tree_indir(indir, treefiles_arr)
  treefiles_arr << [File.join(indir,'F.tre'), File.join(indir,'NF.tre')]
  return(treefiles_arr)
end


###################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--tree_indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--general_tree_indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--species_tree', GetoptLong::REQUIRED_ARGUMENT],
  ['--output_species_tree', '--ost', GetoptLong::NO_ARGUMENT],
  ['--fam_list', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
  ['--angst', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
    when /^--outdir$/
      outdir = value
    when /^-t$/
      treefiles_arr << value.split(',')
    when '--tree_indir'
      tree_indirs << value.split(',')
    when '--general_tree_indir'
      general_tree_indir = value
    when /^--species_tree$/
      species_tree_file = value
      #is_output_species_tree = true
    when /^--(output_species_tree|ost)$/
      is_output_species_tree = true
    when /^--fam_list$/
      fam_list_file = value
    when /^--cpu$/
      cpu = value.to_i
    when /^--force$/
      is_force = true
    when /^--tolerate$/
      is_tolerate = true
    when /^--angst$/
      STDERR.puts "is angst!"
      $is_angst = true
  end
end


###################################################################
treefiles_arr = parse_general_tree_indir(general_tree_indir, treefiles_arr) unless general_tree_indir.nil?

treefiles_arr = parse_tree_indir(tree_indirs, treefiles_arr) unless tree_indirs.empty?


###################################################################
species_tree = getTreeObjs(species_tree_file).shift()

taxa_includeds, o2c = getSubRoots(treefiles_arr)

fams_included = read_list(fam_list_file)

lines = getLines(infile)


###################################################################
results = Parallel.map(lines, in_processes:cpu) do |line|
  taxa2fam = Hash.new
  fam2taxa = Hash.new
  fam2tips = Hash.new
  fam, tree_str = line.split("\t")[2,2]
  next unless fams_included.include?(fam) unless fams_included.empty?
  tree = Bio::Newick.new(tree_str).tree
  tree.nodes.each do |node|
    # note that the last "_10" will be removed from each tip name
    taxa = $is_angst ? getSortedTaxa(tree.tips(node), true, true, false) : getSortedTaxa(tree.tips(node))
    taxa2fam[taxa]=Hash.new if not taxa2fam.include? taxa
    fam2taxa[fam]=Hash.new if not fam2taxa.include? fam
    if node.name !~ /^\d+\|/
      taxa2fam[taxa][fam] = taxa.size > 1 ? node.bootstrap : node.name.split(' ')[-1].to_i
      fam2taxa[fam][taxa] = taxa.size > 1 ? node.bootstrap : node.name.split(' ')[-1].to_i
    else
      taxa2fam[taxa][fam] = taxa.size > 1 ? node.bootstrap : node.name.split('|')[0].to_i
      fam2taxa[fam][taxa] = taxa.size > 1 ? node.bootstrap : node.name.split('|')[0].to_i
    end
    fam2tips[fam] = [] unless fam2tips.include?(fam)
    tree.tips(node).each do |node|
      node_name_arr = node.name.split(' ')
      no_of_genes = node_name_arr[-1].to_i
      next if no_of_genes == 0
      taxon = node_name_arr[0, node_name_arr.size-1].join('_')
      fam2tips[fam] << taxon
    end
  end
  [taxa2fam, fam2taxa, fam2tips]
end


results.each do |hs|
  h1, h2, h3 = hs
  next if h1.nil?
  h1.each_pair do |taxa, v|
    v.each_pair do |fam, count|
      taxa2fam[taxa][fam] = count
    end
  end
  fam2taxa.merge!(h2)
  fam2tips.merge!(h3)
end



###################################################################
if is_output_species_tree
  species_tree.internal_nodes.each do |node|
    taxa = getSortedTaxa(species_tree.tips(node), true, true, false)
    node.bootstrap = taxa2fam[taxa].values.select{|i|i>0}.size
  end
  puts species_tree.cleanNewick()
  exit
end


###################################################################
res_outdir = File.join(outdir, 'res')
tip_outdir = File.join(outdir, 'tip')
mkdir_with_force(res_outdir, is_force, is_tolerate)
mkdir_with_force(tip_outdir, is_force, is_tolerate)


###################################################################
Parallel.map(taxa_includeds, in_processes: taxa_includeds.size) do |taxa_included|
  index = taxa_includeds.index(taxa_included)
  outfile1 = File.join(res_outdir, o2c[index])
  outfile2 = File.join(tip_outdir, o2c[index])
  out_fh1 = File.open(outfile1, 'w')
  out_fh2 = File.open(outfile2, 'w')

  fam2taxa.each_pair do |fam, v|
    out_fh1.puts [fam, taxa_included.map{|i|v[i]}, taxa_included.map{|i|v[i]}.reduce(:-)].join("\t")
  end

  fam2tips.each_pair do |fam, tips|
    taxa = taxa_included[0]
    out_fh2.puts [fam, (taxa & tips).size.to_f/taxa.size].join("\t")
  end

  out_fh1.close
  out_fh2.close
end

puts "DONE!"


