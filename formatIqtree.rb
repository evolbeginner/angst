#! /usr/bin/env ruby


#########################################################################
DIR=File.dirname($0)
$: << File.join(DIR, 'lib')


#########################################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'util'


#########################################################################
CHANGEGENENAME = File.join(DIR, 'changeGeneName.rb')

indir = nil
outdir = nil
suffix = 'ufboot'
n = 100
cpu = 1
is_force = false

infiles = Array.new


#########################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--suffix', GetoptLong::REQUIRED_ARGUMENT],
  ['-n', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--indir$/
      indir = value
    when /^--outdir$/
      outdir = value
    when /^--suffix$/
      suffix = value
    when /^-n$/
      n = value.to_i
    when /^--cpu$/
      cpu = value.to_i
    when /^--force$/
      is_force = true
  end
end


#########################################################################
mkdir_with_force(outdir, is_force)

infiles_1 = read_infiles(indir)
infiles_1.each do |subindir|
  infiles << `find #{subindir}/ -name '*#{suffix}'`.split("\n")
end

infiles.flatten!

Parallel.map(infiles, in_processes: cpu) do |infile|
  c = getCorename(infile)
  `mkdir -p #{outdir+'/'+c} >/dev/null`
  outfile = File.join(outdir, c, c+'.bootstrap.trees')
  `ruby #{CHANGEGENENAME} -i #{infile} -n #{n} > #{outfile}`
end


