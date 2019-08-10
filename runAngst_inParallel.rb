#! /usr/bin/env ruby


##############################################################
DIR = File.dirname($0)
$: << File.join(DIR, 'lib')


##############################################################
require 'getoptlong'
require 'parallel'

require 'Dir'


##################################################################
DIR = File.dirname($0)
RUNANGST = File.join(DIR, 'runAngst.rb')
GETSUBTREE = File.join(DIR, 'getSubtree.rb')


##################################################################
$ANGST = File.expand_path("~/software/phylo/angst/angst_lib/AnGST.py")
indir = nil
outdir = nil
is_force = false
is_tolerate = false
cpu = 2
species_tree_file = nil
range = {
  :hgt  =>  '0,9',
  :dup  =>  '0,9',
  :los  =>  '1,1',
}
ranges = Array.new
is_subtree = false
is_ultrametric = false


genes = Array.new


##################################################################
def get_tree_outfile(gene, indir)
  tree_file_basename = [gene, 'bootstrap.trees'].join('.')
  tree_outfile = File.join(indir, gene, tree_file_basename)
  return(tree_outfile)
end


##################################################################
opts = GetoptLong.new(
  ['--angst', GetoptLong::REQUIRED_ARGUMENT],
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['-s', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
  ['--hgt', GetoptLong::REQUIRED_ARGUMENT],
  ['--dup', '--dupli', GetoptLong::REQUIRED_ARGUMENT],
  ['--los', '--loss', GetoptLong::REQUIRED_ARGUMENT],
  ['--range', GetoptLong::REQUIRED_ARGUMENT],
  ['--subtree', GetoptLong::NO_ARGUMENT],
  ['--ultrametric', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--angst$/
      $ANGST = File.expand_path(value)
    when /^--indir$/
      indir = value
    when /^--cpu$/
      cpu = value.to_i
    when /^-s$/
      species_tree_file = value
    when /^--outdir$/
      outdir = value
    when /^--force$/
      is_force = true
    when /^--tolerate$/
      is_tolerate = true
    when /^--hgt$/
      range[:hgt] = value
    when /^--dup(li)?$/
      range[:dup] = value
    when /^--loss?$/
      range[:los] = value
    when /^--range$/
      ranges = value.split(/[-,]/).map{|i|i.to_i}
    when /^--subtree$/
      is_subtree = true
    when /^--ultrametric$/
      is_ultrametric = true
  end
end


mkdir_with_force(outdir, is_force, is_tolerate)


##################################################################
Dir.foreach(indir) do |b|
  next if b =~ /^\./
  next unless File.directory?(File.join(indir,b))
  genes << b
end


#genes.sort_by!{|gene| File.size(get_tree_outfile(gene, indir))}.reverse!
#genes.sort_by!{|gene| File.size(get_tree_outfile(gene, indir))}
genes.sort!
genes = genes[ranges[0]-1, ranges[1]-ranges[0]+1] if not ranges.empty?
genes.shuffle!


##################################################################
results = Parallel.map(genes, in_processes: cpu) do |gene|
  tree_outfile = get_tree_outfile(gene, indir)
  tree_file = species_tree_file
  add_cmd = ''
  add_cmd << '--ultrametric ' if is_ultrametric

  if is_subtree
    subtree_outdir = File.join(outdir, "../subtree/#{gene}")
    `ruby #{GETSUBTREE} -s #{species_tree_file} -g #{tree_outfile} --outdir #{subtree_outdir} --force --tolerate`
    subtree_file = File.join(subtree_outdir, 'subtree')
    if File.size(subtree_file) < File.size(species_tree_file)
      tree_file = subtree_file
      add_cmd << "--subtree_dir #{subtree_outdir} "
    end
  end

  cmd = "ruby #{RUNANGST} --angst #{$ANGST} --species_tree #{tree_file} --gene_tree #{tree_outfile} --outdir #{outdir} --tolerate --gene #{gene} --hgt #{range[:hgt]} --dup #{range[:dup]} --los #{range[:los]} #{add_cmd}"
  system(cmd)

end


