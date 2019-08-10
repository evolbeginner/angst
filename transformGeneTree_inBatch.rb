#! /usr/bin/env ruby


##################################################
DIR = File.dirname($0)
$: << File.join(DIR, 'lib')


##################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'processbar'


##################################################
TRANSFORMGENETREE = File.join(DIR, 'transformGeneTree.rb')


##################################################
indir = nil
outdir = nil
species_tree_file = nil
range = Array.new
cpu = 1
is_force = false

genes = Array.new


##################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--range', GetoptLong::REQUIRED_ARGUMENT],
  ['-s', '--species_tree', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--indir$/
      indir = value
    when /^--outdir$/
      outdir = value
    when /^-s|--species_tree$/
      species_tree_file = value
    when /^--range$/
      range = value.split(/[-,]/).map{|i|i.to_i}
    when /^--cpu$/
      cpu = value.to_i
    when /^--force$/
      is_force = true 
  end
end


##################################################
mkdir_with_force(outdir, is_force)


##################################################
Dir.foreach(indir) do |b|
  next if b =~ /^\./
  genes << b
end


genes.sort!
genes = genes[range[0]-1, range[1]-range[0]+1] if not range.empty?
genes.shuffle!


##################################################
Parallel.map(genes, in_processes: cpu) do |gene|
  indir2 = File.join(indir, gene)
  Dir.foreach(indir2) do |b|
    next if b =~ /^\./
    gene_tree_file = File.join(indir2, b)
    outfile = File.join(outdir, gene, b)
    mkdir_with_force(File.dirname(outfile), true)
    `ruby #{TRANSFORMGENETREE} -s #{species_tree_file} -g #{gene_tree_file} > #{outfile}`
    exit 1 if $?.exitstatus != 0
  end
end


puts "Transformation successfully done!"
puts


