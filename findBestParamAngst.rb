#! /usr/bin/env ruby


require 'getoptlong'


#######################################################################
dir = File.dirname($0)


#######################################################################
# CONSTANTS
CALCULATEFLUXSIZE = File.join(dir, 'calculateFluxSize.rb')


#######################################################################
# VARIABLES
indir = nil
species_tree_file = nil


cat_info = Hash.new{|h,k|h[k]=0}


#######################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['-s', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--indir$/
      indir = value
    when /^-s$/
      species_tree_file = value
  end
end


#######################################################################
Dir.foreach(indir).each do |cat|
  next if cat =~ /^\./
  next if not File.directory?(File.join(indir,cat))

  cat_arr = cat.split('-').map{|i|i.to_i}
  total = 0
  indir2 = File.join(indir, cat, 'res')
  Dir.foreach(indir2).each do |gene|
    next if gene =~ /^\./
    count_file = File.join(indir2, gene, 'AnGST.counts')
    begin
      a=`ruby #{CALCULATEFLUXSIZE} -i #{count_file} --species_tree #{species_tree_file}`.chomp.to_i
    rescue Exception => e
      puts e.message
    end
    cat_info[cat_arr] += a
  end
end


#cat_info.sort.to_h.each_pair do |cat_arr, counter|
cat_info.sort.each do |cat_arr, counter|
  puts [cat_arr.join('-'), counter].join("\t")
end


