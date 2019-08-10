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


##########################################################
species_tree_file = nil
logBase = nil
type = 'absolute'
is_tip_size = false


##########################################################
def changeTipNameInTheTree(species_tree)
  species_tree.allTips.each do |tip|
    tip.bootstrap = tip.name.split(/ /)[-1].to_i
    arr = tip.name.split(/ /)
    tip.name = tip.name.split(/ /)[0,arr.size-1].join('_')
  end
  return(species_tree)
end


def modifyBranchLength(species_tree, logBase, type, is_tip_size)
  species_tree.each_edge do |node0, node1, edge|
    next if node0.bootstrap.nil? or node1.bootstrap.nil?
    case type
      when 'absolute'
        edge.distance = convertToLogValue(node1.bootstrap, logBase)
      when 'relative'
        edge.distance = node1.bootstrap-node0.bootstrap
        #edge.distance = convertToLogValue((node1.bootstrap-node0.bootstrap), logBase)
    end
  end

  if is_tip_size
    species_tree.allTips.map{|tip|tip.name = [tip.bootstrap.to_s, tip.name].join('|')}
  end

  species_tree.allTips.map{|tip|tip.bootstrap=nil}

  return(species_tree)
end



##########################################################
if __FILE__ == $0; then
  opts = GetoptLong.new(
    ['-s', '--species_tree', GetoptLong::REQUIRED_ARGUMENT],
    ['--log', GetoptLong::REQUIRED_ARGUMENT],
    ['--type', GetoptLong::REQUIRED_ARGUMENT],
    ['--tip_size', GetoptLong::NO_ARGUMENT],
  )


  opts.each do |opt, value|
    case opt
      when /^(-s|--species_tree)$/
        species_tree_file = value
      when /^--log$/
        logBase = value.to_i
      when /^--type$/
        type = value
      when /^--tip_size$/
        is_tip_size = true
    end
  end


  ##########################################################
  species_tree = getTreeObjs(species_tree_file).shift()

  species_tree = changeTipNameInTheTree(species_tree)

  species_tree = modifyBranchLength(species_tree, logBase, type, is_tip_size)
  
  case type
    when 'absolute'
      species_tree.normalizeBranchLength!
    when 'relative'
      species_tree.normalizeBranchLengthGainAndLoss!
  end

  puts species_tree.cleanNewick()

end


