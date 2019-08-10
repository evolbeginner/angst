#! /usr/bin/env ruby


####################################################################
DIR = File.dirname($0)
$: << File.join(DIR, 'lib')


####################################################################
require 'getoptlong'

require 'tree'


####################################################################
treefile = nil
is_remove_prior = false
is_add_prior = false


####################################################################
opts = GetoptLong.new(
  ['-i', '-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--remove_prior', GetoptLong::NO_ARGUMENT],
  ['--add_prior', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when'-i', '-t'
      treefile = value
    when '--remove_prior'
      is_remove_prior = true
    when '--add_prior'
      is_add_prior = true
  end
end


####################################################################
tree = getTreeObjs(treefile).shift

tree.allTips.each do |tip|
  if is_remove_prior
    tip_name_arr = tip.name.split('|')
    n = tip_name_arr.shift.to_i
    tip.name = tip_name_arr.join('_')
  else
    tip_name_arr = tip.name.split(' ')
    n = tip_name_arr.pop.to_i
    tip.name = tip_name_arr.join('_')
  end
  tip.name = [n, tip.name].join('|') if is_add_prior
end

puts tree.cleanNewick


