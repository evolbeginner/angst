#! /usr/bin/env ruby


############################################
dir = File.dirname($0)
$: << File.join(dir, 'lib')


############################################
require 'getoptlong'
require 'bio'

require 'tree'


############################################
#ruby calculateFluxSize.rb -i $i/AnGST.counts --species rooted_species-2.tree


############################################
infile = nil
species_tree_file = nil


############################################
def readInfile(infile)
  count_info = Hash.new
  begin
    in_fh = File.open(infile, 'r')
  rescue
    STDERR.puts "Infile #{infile} cannot be opened! Exiting ......"
    exit 1
  end
  in_fh.each_line do |line|
    #23-24: 1
    line.chomp!
    line_arr = line.split(': ')
    nodes = line_arr[0].split('-').sort
    count = line_arr[-1].to_i
    count_info[nodes] = count
  end
  in_fh.close
  return(count_info)
end


def getGenomeFluxSize(species_tree, count_info)
  fluxSize = 0
  species_tree.internal_nodes.each do |node|
    next if node.isTip?(species_tree)
    taxa = species_tree.tips(node).map{|i|i.name}.sort
    count = count_info[taxa]

    children = species_tree.children(node)
    children.each do |child|
      count_2 = nil
      if child.isTip?(species_tree)
        count_2 = count_info[[child.name]]
      else
        tip_species = species_tree.tips(child).map{|i|i.name}.sort
        count_2 = count_info[tip_species]
      end
      fluxSize += (count - count_2).abs
    end
  end
  return(fluxSize)
end



############################################
if __FILE__ == $0; then
  opts = GetoptLong.new(
    ['-i', GetoptLong::REQUIRED_ARGUMENT],
    ['-s', '--species_tree', GetoptLong::REQUIRED_ARGUMENT],
  )


  opts.each do |opt, value|
    case opt
      when /^-i$/
        infile = value
      when /^(-s|--species_tree)$/
        species_tree_file = value
    end
  end


  ############################################
  count_info = readInfile(infile)

  species_tree = getTreeObjs(species_tree_file).shift()

  fluxSize = getGenomeFluxSize(species_tree, count_info)

  puts fluxSize # output result

end

