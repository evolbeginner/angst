#! /usr/bin/env ruby


###########################################################
require 'getoptlong'

require 'Dir'
require 'util'


###########################################################
MAP_GAIN_LOSS = File.expand_path("~/project/Rhizobiales/scripts/angst/mapGainLoss.rb")


indir = nil
angst_indir = nil
indir2 = nil

gene2id = Hash.new


###########################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--angst_indir', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--indir'
      indir = value
    when '--angst_indir'
      angst_indir = value
  end
end


###########################################################
infiles = read_infiles(indir)
infiles.each do |infile|
  c = getCorename(infile)
  next if c == 'notes'
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    #fliI	COG1157
    line.chomp!
    gene, id = line.split("\t")
    gene2id[gene] = id
  end
  in_fh.close
end


###########################################################
indir2 = File.join(angst_indir, 'no_trimmed/angst/results')


###########################################################
puts ["\t", '#Family	Ancestral Family Size Tree'].join("\t")
gene2id.each_pair do |gene, id|
  #puts [gene, id].join("\t")
  if Dir.exist?(File.join(indir2, "angst/3-2-1-0/res/", id))
    a = `ruby #{MAP_GAIN_LOSS} -s #{indir2}/species.tree --indir #{indir2}/angst/3-2-1-0/res/ --style bootstrap --countType gene --rela #{indir2}/species.rela --tip_size --fam #{id} | sed "2!d"`.chomp
    puts ["\t", id, a].join("\t")
  end
end
puts ["\t", 'Total Ancestral Size'].join("\t")


