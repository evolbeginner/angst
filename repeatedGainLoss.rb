#! /usr/bin/env ruby


#########################################################
DIR = File.dirname($0)

$: << File.expand_path("~/project/Rhizobiales/scripts/correlTraitGene/")
$: << File.join(DIR, 'lib')


##########################################################
require 'getoptlong'

require 'Dir'
require 'Hash'
require 'obtainCandidateFams'
require 'gainAndLoss'


##########################################################
$ANNOT_RAST_FILE = File.expand_path("~/project/Rhizobiales/results/RAST/results/orthofinder/final.out")


##########################################################
infiles = Array.new
outdir = nil
taxa = Array.new
num = nil
is_force = false
is_tolerate = false


info = multi_D_Hash(3)
#gainedFams = multi_D_Hash(2)
#gainedGenes = multi_D_Hash(2)
#lostFams = multi_D_Hash(2)
#lostGenes = multi_D_Hash(2)

outfiles = Hash.new
out_fhs = Hash.new


##########################################################
class FAM_RAST
  attr_accessor :categories, :subcategories, :subsystems, :locus, :annot, :str
  def initialize
    @categories = []
    @subcategories = []
    @subsystems = []
    @str = []
    autoStr
  end
  def autoStr
    @str << @categories.join('; ') #cat
    @str << @subcategories.join('; ') #subcat
    @str << @subsystems.join('; ') #subsys
    @str << @locus
    @str << @annot
  end
end


##########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--taxa', GetoptLong::REQUIRED_ARGUMENT],
  ['-n', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infiles << value.split(',')
    when '--indir'
      infiles << read_infiles(value)
    when '--outdir'
      outdir = value
    when '--taxa'
      taxa << value.split(',')
    when '-n'
      num = value.to_i
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
  end
end


##########################################################
infiles.flatten!
taxa.flatten!

if num.nil?
  num = infiles.size
end

mkdir_with_force(outdir, is_force, is_tolerate)


##########################################################
famInfo = readAnnotFile($ANNOT_FILE)
famInfo.merge!(readAnnotFile($ANNOT_KEGG_FILE))
famInfo.merge!(readAnnotRastFile($ANNOT_RAST_FILE))


##########################################################
infiles.each do |infile|
  b = File.basename(infile)
  next if not taxa.include?(b) if not taxa.empty?
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    fam = line_arr[0]
    child_num, parent_num = line_arr[1, 2].map{|i|i.to_i}
    if child_num > parent_num
      info[:gainedGenes][fam][b] = ''
      if parent_num == 0
        info[:gainedFams][fam][b] = ''
      end
    elsif child_num < parent_num
      info[:lostGenes][fam][b] = ''
      if child_num == 0
        info[:lostFams][fam][b] = ''
      end
    end
  end
  in_fh.close
end


##########################################################
outfiles[:gainedGenes] = File.join(outdir, 'gainedGenes.list')
outfiles[:gainedFams] = File.join(outdir, 'gainedFams.list')
outfiles[:lostFams] = File.join(outdir, 'lostFams.list')
outfiles[:lostGenes] = File.join(outdir, 'lostGenes.list')

outfiles.each_pair do |type, file|
  out_fhs[type] = File.open(file, 'w')
end

info.each_pair do |type, v1|
  out_fh = out_fhs[type]
  v1.sort_by{|fam, v2|v2.size}.reverse.to_h.select{|fam, v2| v2.size>=num }.each_pair do |fam, v2|
    famInfo[fam] = FAM.new if not famInfo.include?(fam)
    taxa_info_str = taxa.map{|b| info[type][fam].include?(b) ? b : ''}
    out_fh.puts [fam, taxa_info_str, famInfo[fam].func_abbr, famInfo[fam].func].flatten.join("\t")
  end
end

out_fhs.each_pair do |type, out_fh|
  out_fh.close
end


