#! /usr/bin/env ruby


##########################################################################
DIR = File.dirname($0)
$: << File.join(DIR)
$: << File.join(DIR, '../lib')


##########################################################################
require 'getoptlong'
require 'bio'

require 'chang_yong'
require 'tree'
require 'basic_math'
require 'mapGainLoss'


##########################################################################
infile = nil
treefile = nil
pp_min = 0.75
logBase = nil
type = 'absolute'
is_normalizeBranchLength = true

has_family_started = false
node_arr = Array.new
numOfFams = Hash.new{|h,k|h[k]=[]}
fams_included = Array.new


##########################################################################
class Count
  attr_accessor :node_name, :type
  def initialize(node_name, type)
    @node_name = node_name
    @type = type
  end
end


##########################################################################
def get_node_arr(line)
  line_arr = line.split("\t")
  arr = line_arr[3,line_arr.size-3]
  node_arr = Array.new
  arr.each do |i|
    node_name, type = i.split(':')
    count = Count.new(node_name, type)
    node_arr << count
  end
  return(node_arr)
end


def addGeneNumToTreeBranchLength(tree, logBase, type)
  tree.each_edge do |node0, node1, edge|
    next if node0.bootstrap.nil? or node1.bootstrap.nil?
    if type == 'absolute'
      edge.distance = convertToLogValue(node1.bootstrap, logBase)
    elsif type == 'relative'
      edge.distance = node1.bootstrap-node0.bootstrap
    end
  end
  return(tree)
end


##########################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--pp', GetoptLong::REQUIRED_ARGUMENT],
  ['--log', GetoptLong::REQUIRED_ARGUMENT],
  ['--type', GetoptLong::REQUIRED_ARGUMENT],
  ['--fam', GetoptLong::REQUIRED_ARGUMENT],
  ['--fam_list', GetoptLong::REQUIRED_ARGUMENT],
  ['--no_norm_bl', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
    when /^-t$/
      treefile = value
    when /^--pp$/
      pp_min = value.to_f
    when /^--log$/
      logBase = value.to_i
    when /^--type$/
      type = value
    when '--fam'
      fams_included << value.split(',')
    when '--fam_list'
      fams_included << read_list(value).keys
    when /^--no_norm_bl$/
      is_normalizeBranchLength = false
  end
end


fams_included.flatten!.uniq!


##########################################################################
tree = getTreeObjs(treefile).shift

tree.internal_nodes.each do |internal_node|
  internal_node.name = internal_node.bootstrap.to_s
  internal_node.bootstrap = nil
end


##########################################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  next if line =~ /^#/

  if not has_family_started
    node_arr = get_node_arr(line) if line =~ /^Family/
    has_family_started = true if line =~ /^ABSENT\t/
    next
  end

  line_arr = line.split("\t")
  fam_name = line_arr[0]
  next unless fams_included.include?(fam_name) unless fams_included.empty?
  useful_arr = line_arr[3,line_arr.size-3]
  useful_arr.each_with_index do |ele, index|
    count = node_arr[index]
    case count.type
      when /^[1m]$/
        numOfFams[count.node_name] << fam_name if ele.to_f >= pp_min
    end
  end
end
in_fh.close

#Family	Pattern	C0/e0,d0,l0,t0	taxon:1	taxon:m	taxon:gain	taxon:loss	taxon:expansion	taxon:reduction


##########################################################################
numOfFams = numOfFams.map{|node_name, v|[node_name, v.uniq]}.to_h

tree.each_node do |node|
  node.bootstrap = numOfFams.include?(node.name) ? numOfFams[node.name].size : 0
  #puts [node, node.bootstrap].join("\t")
  if node.isTip?(tree)
    node.name = [node.bootstrap.to_s, node.name].join('|')
    node.name.gsub!('!', '_')
  else
    node.name = nil
  end
end

tree = addGeneNumToTreeBranchLength(tree, logBase, type)


##########################################################################
if is_normalizeBranchLength
  case type
    when 'absolute'
      tree.normalizeBranchLength!
    when 'relative'
      tree.normalizeBranchLengthGainAndLoss!
  end
end

tree.allTips.map{|tip|tip.bootstrap=nil}

puts tree.cleanNewick


