#! /usr/bin/env ruby


#####################################################
dir = File.dirname($0)
$: << File.join(dir, 'lib')


#####################################################
require 'getoptlong'
require 'bio'

require 'tree'


#####################################################
infile = nil
outfile = nil


#####################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-o', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
    when /^-o$/
      outfile = value
  end
end


#####################################################
if infile == '-'
  tree = getTreeObjs($stdin, 1).shift()
else
  tree = getTreeObjs(infile, 1).shift()
end

puts tree.allTips.map{|i|i.name}.join(' ')


