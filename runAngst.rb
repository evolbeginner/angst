#! /usr/bin/env ruby


##############################################################
dir = File.dirname($0)
$: << File.join(dir, 'lib')


##############################################################
require 'getoptlong'

require 'Dir'
require 'processbar'


##############################################################
$ANGST = File.expand_path("~/software/phylo/angst/angst_lib/AnGST.py")


##############################################################
species_tree_file = nil
gene_tree_file = nil
outdir = nil
gene = nil
subtree_dir = nil
is_ultrametric = false
is_force = false
is_tolerate = false

cat_info = Hash.new
cat_info[:hgt] = 0.upto(9).to_a
cat_info[:dup] = 0.upto(9).to_a
cat_info[:los] = 1.upto(1).to_a
cat_info[:spc] = 0.upto(0).to_a


combos = Array.new


##############################################################
class String
  def expand2array
    a = split(',').map{|i|i.to_i}
    return(a[0].upto(a[1]).to_a)
  end
end


##############################################################
def create_penalty_file(outfile, combo)
  out_fh = File.open(outfile, 'w')
  out_fh.puts ['hgt:', combo[0]].join(' ')
  out_fh.puts ['dup:', combo[1]].join(' ')
  out_fh.puts ['los:', combo[2]].join(' ')
  out_fh.puts ['spc:', combo[3]].join(' ')
  out_fh.close
end


##############################################################
opts = GetoptLong.new(
  ['--angst', GetoptLong::REQUIRED_ARGUMENT],
  ['--species_tree', GetoptLong::REQUIRED_ARGUMENT],
  ['--gene_tree', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--gene', GetoptLong::REQUIRED_ARGUMENT],
  ['--hgt', GetoptLong::REQUIRED_ARGUMENT],
  ['--dup', GetoptLong::REQUIRED_ARGUMENT],
  ['--los', GetoptLong::REQUIRED_ARGUMENT],
  ['--subtree_dir', GetoptLong::REQUIRED_ARGUMENT],
  ['--ultrametric', GetoptLong::NO_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--angst$/
      $ANGST = File.expand_path(value)
    when /^--species_tree$/
      species_tree_file = value
    when /^--gene_tree$/
      gene_tree_file = value
    when /^--outdir$/
      outdir = value
    when /^--gene$/
      gene = value
    when /^--hgt$/
      cat_info[:hgt] = value.expand2array
    when /^--dup$/
      cat_info[:dup] = value.expand2array
    when /^--los$/
      cat_info[:los] = value.expand2array
    when /^--subtree_dir$/
      subtree_dir = value
    when /^--ultrametric$/
      is_ultrametric = true
    when /^--force$/
      is_force = true
    when /^--tolerate$/
      is_tolerate = true
  end
end


##############################################################
cat_info[:hgt].each do |hgt|
  cat_arr = Array.new
  cat_info[:dup].each do |dup|
    cat_info[:los].each do |los|
      cat_info[:spc].each do |spc|
        combos << [hgt, dup, los, spc]
      end
    end
  end
end


mkdir_with_force(outdir, is_force, is_tolerate)


##############################################################
combos.each_with_index do |combo, index|
  time_start = Time.now.to_i

  cat = combo.join('-')
  output_dir = File.join(outdir, cat, 'res', gene)
  ctl_dir = File.join(outdir, cat, 'ctl')
  mkdir_with_force(output_dir, is_force, is_tolerate)
  mkdir_with_force(ctl_dir, is_force, is_tolerate)

  time_outfile = File.join(outdir, cat, 'time')
  time_outfh = File.open(time_outfile, 'a')

  penalty_file = File.join(outdir, cat, 'penalty.txt')
  create_penalty_file(penalty_file, combo)

  ctl_outfile = File.join(ctl_dir, gene)
  out_fh = File.open(ctl_outfile, 'w')
  out_fh.puts "force=True"
  out_fh.puts "species=#{species_tree_file}"
  out_fh.puts "gene=#{gene_tree_file}"
  out_fh.puts "output=#{output_dir}"
  out_fh.puts "penalties=#{penalty_file}"
  out_fh.puts "ultrametric=True" if is_ultrametric
  out_fh.close

  cmd = "python #{$ANGST} #{ctl_outfile}"
  `#{cmd} 2>/dev/null`
  if $?.exitstatus != 0
    puts "Error!\t#{gene_tree_file}"
  end
  #processbar(index+1, combos.size)
  #print "\t#{gene}"

  time_end = Time.now.to_i
  time_cost = time_end - time_start
  time_outfh.puts [gene, combo.join('-'), time_cost].join("\t")
  time_outfh.close

  if not subtree_dir.nil?
    infile = File.join(subtree_dir, 'diff.counts')
    system("cat #{infile} >> #{output_dir}/AnGST.counts")
  end
end


