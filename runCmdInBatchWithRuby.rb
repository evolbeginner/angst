#! /usr/bin/env ruby


####################################################################
require 'getoptlong'
require 'parallel'


####################################################################
infile = nil
cpu = 1

cmds = Array.new


####################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
    when /^--cpu$/
      cpu = value.to_i
  end
end


####################################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  cmds << line
end
in_fh.close


####################################################################
Parallel.map(cmds, in_processes: cpu) do |cmd|
  `#{cmd}`
end


