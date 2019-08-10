#! /usr/bin/env ruby


###########################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'chang_yong'


###########################################################
ALE_DIR = File.expand_path("~/software/phylo/ALE/build/bin/")
ALEOBSERVE = File.join(ALE_DIR, 'ALEobserve')
ALEML_UNDATED = File.join(ALE_DIR, 'ALEml_undated')
#ALEML_UNDATED = File.join(ALE_DIR, 'ALEml')


###########################################################
indir = nil
subdirs = Array.new
outdir = nil
species_tree_file = nil
cpu = 1
is_force = false
is_tolerate = false


###########################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['-s', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--indir'
      indir = value
    when '--outdir'
      outdir = value
    when '-s'
      species_tree_file = File.expand_path(value)
    when '--cpu'
      cpu = value.to_i
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
  end
end


###########################################################
mkdir_with_force(outdir, is_force, is_tolerate)

subdirs = read_infiles(indir)

PWD = Dir.pwd

Parallel.map(subdirs, in_processes: cpu) do |subdir|
  Dir.chdir(PWD)
  b = File.basename(subdir)
  #puts b
  b_tree = b + '.bootstrap.trees'
  infile = File.expand_path(File.join(subdir, b+'.bootstrap.trees'))
  outdir2 = File.join(PWD, outdir, b)
  mkdir_with_force(outdir2)
  Dir.chdir(outdir2)
  `ln -s #{infile}`
  `#{ALEOBSERVE} #{b_tree}`
  ale_outfile = [b_tree, 'ale'].join('.')
  `#{ALEML_UNDATED} #{species_tree_file} #{ale_outfile}`
end


