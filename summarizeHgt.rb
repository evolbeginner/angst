#! /usr/bin/env ruby


##################################################################
DIR = File.dirname(__FILE__)
$: << File.join(DIR, 'lib')


##################################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'chang_yong'
require 'tree'
require 'util'


##################################################################
TEMPLATE_FILE = File.expand_path("~/project/Rhizobiales/scripts/iTOL/template/connections")


##################################################################
indir = nil
tree_indir = nil
cpu = 1
fam_list_file = nil
species_rela_file = nil
lifestyle_list_file = nil
is_output_template = false


dr_count = Hash.new{|h,k|h[k]=0}
subtreeRepresentatives = Hash.new
tipNames2lifestyle = Hash.new
taxaCount = Hash.new{|h,k|h[k]=0}


##################################################################
class SubtreeRepresentative
  attr_accessor :name, :group
  def initialize(arr, group)
    @name = arr.join('|')
    @group = group
  end
end


##################################################################
def generateSubtreeRepresentatives(tree, group)
  subtreeRepresentatives = Hash.new
  tree.nodes.each_with_index do |node, index|
    arr = tree.tips(node).map{|tip|tip.name.gsub(' ', '_')}.sort
    subtreeRepresentative = SubtreeRepresentative.new(arr, group)
    subtreeRepresentatives[arr] = subtreeRepresentative
  end
  return(subtreeRepresentatives)
end


def readLifestyleFile(lifestyle_list_file)
  tipNames2lifestyle = Hash.new
  in_fh = File.open(lifestyle_list_file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    tipNames = line_arr[0].split('|')
    lifestyle = line_arr[1]
    tipNames2lifestyle[tipNames] = lifestyle
  end
  in_fh.close
  return(tipNames2lifestyle)
end


def  read_event_file(event_file)
  drs = Array.new
  return(drs) if not File.exists?(event_file)
  in_fh = File.open(event_file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    #[hgt]: 93-94-95-96 --> 84-85-86
    next if line !~ /^\[hgt\]/
    next if line !~ /(\S+) \-\-\> (\S+)$/
    donor, receptor = $1, $2
    drs << [donor, receptor]
  end
  in_fh.close
  return(drs)
end


def read_species_rela_file(species_rela_file)
  num2taxon = Hash.new
  in_fh = File.open(species_rela_file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    taxon, num = line_arr
    num2taxon[num] = taxon
  end
  in_fh.close
  return(num2taxon)
end


##################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--tree_indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--fam_list', GetoptLong::REQUIRED_ARGUMENT],
  ['--species_rela', GetoptLong::REQUIRED_ARGUMENT],
  ['--lifestyle_list', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--indir$/
      indir = value
    when /^--tree_indir/
      tree_indir = value
    when /^--cpu$/
      cpu = value.to_i
    when /^--fam_list/
      fam_list_file = value
    when /^--species_rela$/
      species_rela_file = value
    when '--lifestyle_list'
      lifestyle_list_file = value
  end
end


##################################################################
species_rela_file = File.join(File.dirname(indir), '../../../', 'species.rela') if species_rela_file.nil?
num2taxon = read_species_rela_file(species_rela_file)

fams_included = read_list(fam_list_file)

treefiles = read_infiles(tree_indir)
treefiles.each do |treefile|
  b = getCorename(treefile)
  tree = getTreeObjs(treefile).shift
  subtreeRepresentatives.merge! generateSubtreeRepresentatives(tree, b)
end

tipNames2lifestyle = readLifestyleFile(lifestyle_list_file)


##################################################################
infiles = read_infiles(indir)

results = Parallel.map(infiles, in_processes:cpu) do |subdir|
  event_file = File.join(subdir, 'AnGST.events')
  b = File.basename(subdir)
  [] if not fams_included.include?(b) unless fams_included.empty?
  drs = read_event_file(event_file)
  drs
end


results.each do |drs|
  next if drs.empty?
  drs.each do |dr|
    dr_count[dr] += 1
  end
end


##################################################################
dr_count.each_pair do |dr, count|
  taxa_arr = dr.map{|num_str| num_str.split('-').map{|num|num2taxon[num]}.sort }
  #next if not taxa_arr.all?{|i|subtreeRepresentatives.include?(i)}
  next if not taxa_arr.any?{|i|subtreeRepresentatives.include?(i)}
  next if taxa_arr.any?{|i|tipNames2lifestyle[i].include?('X')}
  #next if taxa_arr.all?{|i|tipNames2lifestyle[i] == 'F'}
  outTaxa, inTaxa = taxa_arr #tipNames2lifestyle[taxa_arr[0]] == 'M' ? taxa_arr[1] : taxa_arr[0]
  next if not subtreeRepresentatives.include?(inTaxa)
  next if inTaxa.size < 3
  taxaCount[outTaxa] += 1
  next
  if taxa_arr.map{|i|subtreeRepresentatives[i].group}.uniq.size > 1
    p [taxa_arr.map{|i|i.size}, count]
  end
end

taxaCount.sort_by{|k,v|v}.to_h.each_pair do |outTaxa, count|
  puts count
  puts [outTaxa.join('|'), 'Brucella_sp_141012304|Brucella_abortus_93_1', count/10.to_f, 'green'].join(",")
  #NODE1,NODE2,WIDTH,COLOR,LABEL
end


