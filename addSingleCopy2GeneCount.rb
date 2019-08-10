#! /usr/bin/env ruby


#####################################################################
require 'getoptlong'


#####################################################################
OUT2IN_FILE = File.expand_path('~/project/Rhizobiales/data/genome_source/out2in.tbl')


#####################################################################
infile1 = nil
infile2 = nil
is_no_out2in = false


#####################################################################
def readOut2In(infile)
  out2in = Hash.new
  in2out = Hash.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    a1, a2 = line.split("\t")
    out2in[a1] = a2
    in2out[a2] = a1
  end
  in_fh.close
  return([out2in, in2out])
end


def readFirstLine(infile)
  taxa = Array.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    taxa = line.split("\t")
    taxa.shift
    taxa.pop
    break
  end
  in_fh.close
  return(taxa)
end


def getSingleCopyOrthos(infile, out2in)
  ortho2taxon = Hash.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split(" ")
    next if line_arr.count{|i|i=~/\|/} >= 2
    ortho, gene_full = line_arr[0, 2]
    ortho.sub!(':', '')
    taxon_in = gene_full.split('|')[0]
    taxon = out2in.empty? ? taxon_in : out2in[taxon_in]
    ortho2taxon[ortho] = taxon
  end
  in_fh.close
  return(ortho2taxon)
end


#####################################################################
opts = GetoptLong.new(
  ['--i1', GetoptLong::REQUIRED_ARGUMENT],
  ['--i2', GetoptLong::REQUIRED_ARGUMENT],
  ['--no_out2in', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--i1'
      infile1 = value
    when '--i2'
      infile2 = value
    when '--no_out2in'
      is_no_out2in = true
  end
end


#####################################################################
out2in, in2out = readOut2In(OUT2IN_FILE)
out2in, in2out = [{}, {}] if is_no_out2in

taxa = readFirstLine(infile1)

ortho2taxon = getSingleCopyOrthos(infile2, out2in)

ortho2taxon.each_pair do |ortho, taxon|
  index = taxa.index(taxon)
  str = 0.upto(taxa.size-1).map{|i| i == index ? 1 : 0}.join("\t")
  puts [ortho, str, '1'].join("\t")
end


