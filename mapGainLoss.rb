#! /usr/bin/env ruby


##########################################################
dir = File.dirname($0)
$: << dir
$: << File.join(dir, 'lib')


##########################################################
require 'getoptlong'

require 'basic_math'
require 'tree'
require 'calculateFluxSize' 
require 'processbar'
require 'chang_yong'


##########################################################
indir = nil
species_tree_file = nil
countType = 'gene'
logBase = nil
type = 'absolute'
styles = Array.new
relaFile = nil
include_list_file = nil
is_badirate = false
is_tip_size = false

countInfo2 = Hash.new{|h,k|h[k]={}}
fams_included = Array.new


##########################################################
def convertCountInfoToIncludeFamily(countInfo, countInfo2, b)
  countInfo.each_pair do |taxa, count|
    countInfo2[taxa][b] = count
  end
  return(countInfo2)
end


def summarizeCount(species_tree, count_info, countType, logBase, type, styles)
  species_tree.nodes.each do |node|
    taxa = species_tree.tips(node).map{|i|i.name}.sort
    taxa = [node.name] if taxa.empty?
    h = count_info[taxa]
    count = nil
    case countType
      when 'gene'
        count = h.keys.map{|gene|h[gene]}.reduce(:+)
      when 'family'
        count = h.keys.count{|fam|h[fam] >= 1}
    end
    node.bootstrap = count
  end

  if styles.include?('branchLength')
    species_tree.each_edge do |node0, node1, edge|
      next if node0.bootstrap.nil? or node1.bootstrap.nil?
      if type == 'absolute'
        edge.distance = convertToLogValue(node1.bootstrap, logBase)
      elsif type == 'relative'
        edge.distance = node1.bootstrap-node0.bootstrap
      end
    end
    #species_tree.normalizeBranchLength!
  end

  return(species_tree)
end


def convertTipNameToTaxaName(species_tree, relaFile, styles, is_tip_size)
  tipName2taxa = Hash.new
  in_fh = File.open(relaFile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    taxonName, tipName = line.split("\t")
    tipName2taxa[tipName] = taxonName
  end
  in_fh.close

  species_tree.allTips.each do |tip|
    tip.name = tipName2taxa[tip.name]
  end

  if is_tip_size
    species_tree.allTips.map{|tip|tip.name = [tip.bootstrap.to_s, tip.name].join('|')}
  end

  if styles.include?('bootstrap')
    species_tree.allTips.map{|tip|tip.bootstrap=nil}
  end

  return(species_tree)
end



##########################################################
if __FILE__ == $0; then
  opts = GetoptLong.new(
    ['--indir', GetoptLong::REQUIRED_ARGUMENT],
    ['-s', '--species_tree', GetoptLong::REQUIRED_ARGUMENT],
    ['--countType', GetoptLong::REQUIRED_ARGUMENT],
    ['--log', GetoptLong::REQUIRED_ARGUMENT],
    ['--type', GetoptLong::REQUIRED_ARGUMENT],
    ['--style', GetoptLong::REQUIRED_ARGUMENT],
    ['--rela', GetoptLong::REQUIRED_ARGUMENT],
    ['--fam', GetoptLong::REQUIRED_ARGUMENT],
    ['--fam_list', '--include_list', GetoptLong::REQUIRED_ARGUMENT],
    ['--badirate', GetoptLong::NO_ARGUMENT],
    ['--tip_size', GetoptLong::NO_ARGUMENT],
  )


  opts.each do |opt, value|
    case opt
      when /^--indir$/
        indir = value
      when /^(-s|--species_tree)$/
        species_tree_file = value
      when /^--countType$/
        countType = value
      when /^--log$/
        logBase = value.to_i
      when /^--type$/
        type = value
      when /^--style$/
        styles << value.split(',')
      when /^--rela$/
        relaFile = value
      when '--fam'
        fams_included << value.split(',')
      when '--fam_list', '--include_list'
        include_list_file = value
      when '--badirate'
        is_badirate = true
      when /^--tip_size$/
        is_tip_size = true
    end
  end

  styles.flatten!


  ##########################################################
  species_tree = getTreeObjs(species_tree_file).shift()

  fams_included << read_list(include_list_file).keys unless include_list_file.nil?
  fams_included.flatten!
  fams_included.uniq!

  counter = 0
  total = `ls -1 #{indir} | wc -l`.chomp.to_i
  Dir.foreach(indir) do |b|
    counter += 1
    processbar(counter, total)
    next if b =~ /^\./
    next unless fams_included.include?(b) unless fams_included.empty?
    infile = File.join(indir, b, 'AnGST.counts')
    next if not File.exists?(infile)
    countInfo = readInfile(infile)
    countInfo2 = convertCountInfoToIncludeFamily(countInfo, countInfo2, b)
  end
  puts

  species_tree = summarizeCount(species_tree, countInfo2, countType, logBase, type, styles)

  convertTipNameToTaxaName(species_tree, relaFile, styles, is_tip_size) if not relaFile.nil?
  
  case type
    when 'absolute'
      species_tree.normalizeBranchLength!
    when 'relative'
      species_tree.normalizeBranchLengthGainAndLoss!
  end

  puts species_tree.cleanNewick()

end


