#! /usr/bin/env ruby


##########################################################
require 'getoptlong'

require 'chang_yong'
require 'Dir'


##########################################################
gain_loss_infile = nil
pre_infile = nil
posi_infile = nil
prop = 0.5
outfile = nil
is_force = false


final = Hash.new
transition = Hash.new
pre_fams = Hash.new
present = 0
absent = 0


##########################################################
def readPosiInfile(infile)
  h = Hash.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    next if $. == 0
    line_arr = line.split("\t")
    fam = line_arr[0]
    h[fam] = line_arr[1, line_arr.size-1]
  end
  in_fh.close
  return(h)
end


##########################################################
opts = GetoptLong.new(
  ['--gain_loss', '--gl', GetoptLong::REQUIRED_ARGUMENT],
  ['--pre', '-p', GetoptLong::REQUIRED_ARGUMENT],
  ['--posi', GetoptLong::REQUIRED_ARGUMENT],
  ['--prop', GetoptLong::REQUIRED_ARGUMENT],
  ['-o', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--gain_loss', '--gl'
      gain_loss_infile = value
    when '--pre', '-p'
      pre_infile = value
    when '--posi'
      posi_infile = value
    when '--prop'
      prop = value.to_f
    when '-o'
      outfile = value
    when '--force'
      is_force = true
  end
end


##########################################################
posi_fams = readPosiInfile(posi_infile)


##########################################################
in_fh = File.open(pre_infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  line_arr = line.split("\t")
  fam = line_arr[0]
  next if line_arr[1].to_f < prop
  next if not posi_fams.include?(fam)
  pre_fams[fam] = ''
end
in_fh.close


##########################################################
in_fh = File.open(gain_loss_infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  line_arr = line.split("\t")
  fam = line_arr[0]
  child_no, parent_no = line_arr.values_at(1,2).map{|i|i.to_i}
  next if not pre_fams.include?(fam)
  transition[fam] = '' if parent_no == 0 and child_no > 0
  final[fam] = parent_no
end
in_fh.close


##########################################################
outdir = File.dirname(outfile)
mkdir_with_force(outdir, is_force) unless Dir.exists?(outdir)

out_fh = File.open(outfile, 'w')
final.each_pair do |fam, parent_no|
  if parent_no >= 1
    present += 1
    out_fh.puts [fam, 'ancestor', posi_fams[fam]].join("\t")
  else
    absent += 1
  end
end


transition.each_key do |fam|
  out_fh.puts [fam, 'transition', posi_fams[fam]].join("\t")
end


final.select{|fam, no|no == 0}.to_h.each_key do |fam|
  next if transition.include?(fam)
  out_fh.puts [fam, 'after_div', posi_fams[fam]].join("\t")
end

out_fh.close


##########################################################
puts [present, transition.size, absent+present, (present/(absent+present).to_f).round(2)].join("\t")


