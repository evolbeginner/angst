#! /usr/bin/env ruby


####################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'Hash'


####################################################
$FISHER = 'fisher_chi_test.py'
$FDR_CORR = 'fdr_correction0.py'


####################################################
$cpu = 1
rast_file = File.expand_path("~/project/Rhizobiales/results/RAST/results/orthofinder/final.out")
infiles = Array.new
outdir = nil
is_force = false
is_tolerate = false


####################################################
class Rast
  attr_accessor :categories, :subcategories, :subsystems
  def initialize
    @categories = Array.new
    @subcategories = Array.new
    @subsystems = Array.new
  end
end


####################################################
def getGainedLost(infile)
  gained = multi_D_Hash(2)
  no = multi_D_Hash(2)
  lost = multi_D_Hash(2)
  prior = multi_D_Hash(2)
  after = multi_D_Hash(2)

  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    fam = line_arr[0]
    child_num, parent_num = line_arr[1, 2].map{|i|i.to_i}
    if child_num > parent_num
      gained[:fam][fam] = 1
      gained[:gene][fam] = child_num - parent_num
    elsif child_num == parent_num
      no[:fam][fam] = 1
      no[:gene][fam] = child_num
    else
      lost[:fam][fam] = 1
      lost[:gene][fam] = parent_num - child_num
    end

    prior[:gene][fam] = parent_num
    after[:gene][fam] = child_num
    prior[:fam][fam] = parent_num >= 1 ? 1 : 0
    after[:fam][fam] = child_num >= 1 ? 1 : 0
  end
  in_fh.close

  return([gained, no, lost, prior, after])
end


def readRastFile(rast_file)
  rastInfo = Hash.new
  in_fh = File.open(rast_file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    fam = line_arr[0]
    rastInfo[fam] = Rast.new
    rastInfo[fam].categories = line_arr[3].split('; ').uniq if line_arr[3] =~ /\w/
    rastInfo[fam].subcategories = line_arr[4].split('; ').uniq if line_arr[4] =~ /\w/
    rastInfo[fam].subsystems = line_arr[5].split('; ').uniq if line_arr[5] =~ /\w/
  end
  in_fh.close
  return(rastInfo)
end


def getFinal(h, type, final, gain_or_loss, rastInfo)
  h.each_key do |fam|
    next if not rastInfo.include?(fam)
    rast = rastInfo[fam]
    [:categories, :subcategories, :subsystems].each do |level|
      next if rast.send(level).empty?
      rast.send(level).each do |annot|
        final[type][gain_or_loss][level][annot][fam] = h[fam]
      end
    end
  end
  return(final)
end


def outputFinal(final, type, outdir)
  countInfo = multi_D_Hash(3)

  final[type].each_pair do |gain_or_loss, v1|
    v1.each_pair do |level, v2|
      v2.each_pair do |annot, v3|
        #count = v3.size
        count = v3.values.sum
        countInfo[level][annot][gain_or_loss] = count
      end
    end
  end

  countInfo.each_pair do |level, v1|
    pvalue_info = Hash.new
    fdr_info = Hash.new
    total = Hash.new{|h,k|h[k]=0}
    nums = multi_D_Hash(2)
    v1.each_pair do |annot, v2|
      gains = v2.include?(:gained) ? v2[:gained] : 0
      no = v2.include?(:no) ? v2[:no] : 0
      losses = v2.include?(:lost) ? v2[:lost] : 0
      priors = v2.include?(:prior) ? v2[:prior] : 0
      afters = v2.include?(:after) ? v2[:after] : 0
      nums[annot][:gains] = gains
      nums[annot][:no] = no
      nums[annot][:losses] = losses
      nums[annot][:prior] = priors
      nums[annot][:after] = afters
      total[:gains] += gains
      total[:no] += no
      total[:losses] += losses
      total[:prior] += priors
      total[:after] += afters
    end

    results = Parallel.map(v1, in_processes: $cpu) do |annot, v2|
      #puts [type, level, annot, nums[annot][:gains], total[:gains], nums[annot][:after], total[:after]].join("\t")
      #num_str = [nums[annot][:gains], total[:gains], nums[annot][:after], total[:after]].join(',')
      num_str = nil
      num_str = get_num_str(nums, annot, total, false)
      pvalue_info[annot] = `#{$FISHER} --num #{num_str} --type fisher 2>/dev/null`.chomp
      pvalue_info[annot] = pvalue_info[annot]=~/\d/ ? pvalue_info[annot].to_f : 1
      pvalue_info
    end
    results.each do |v|
      pvalue_info.merge!(v)
    end

    pvalues = pvalue_info.values.select{|i|i!=1}
    fdrs = `#{$FDR_CORR} --num #{pvalues.join(',')}`.chomp.split(',').map{|i|i.to_f}
    pvalue_info.select{|k,v|v!=1}.keys.zip(fdrs) do |annot, fdr|
      fdr_info[annot] = fdr
    end

    outfile = File.join(outdir, level.to_s)
    out_fh = File.open(outfile, 'w')
    pvalue_info.sort_by{|k,v|k}.to_h.each_pair do |annot, pvalue|
      #num_str = [nums[annot][:gains], total[:gains], nums[annot].values.sum, total.values.sum].join(',')
      #num_str = [nums[annot][:gains], total[:gains], nums[annot][:after], total[:after]].join(',')
      #num_str = [nums[annot][:gains]-nums[annot][:losses], total[:gains]-total[:losses], nums[annot][:after], total[:after]].join(',')
      num_str = get_num_str(nums, annot, total, true)
      next if num_str.nil?
      fdr = fdr_info.include?(annot) ? fdr_info[annot] : 1
      out_fh.puts [annot, num_str.split(','), pvalue, fdr].flatten.join("\t")
    end
    out_fh.close
    puts outfile
  end
end


def get_num_str(nums, annot, total, is_ori)
  num_str = nil
  if is_ori
    if total[:gains] - total[:losses] > 0
      num_str = [nums[annot][:gains]-nums[annot][:losses], total[:gains]-total[:losses], nums[annot][:after], total[:after]].join(',')
    else
      num_str = [nums[annot][:gains]-nums[annot][:losses], total[:gains]-total[:losses], nums[annot][:prior], total[:prior]].join(',')
    end
  else
    if total[:gains] - total[:losses] > 0
      num_str = [nums[annot][:gains]-nums[annot][:losses], total[:gains]-total[:losses], nums[annot][:after], total[:after]].join(',')
    else
      num_str = [nums[annot][:losses]-nums[annot][:gains], total[:losses]-total[:gains], nums[annot][:prior], total[:prior]].join(',')
    end
  end
  #num_str = nil if (nums[annot][:gains]-nums[annot][:losses]) * (total[:gains]-total[:losses]) < 0
  return(num_str)
end


####################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--rast', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infiles << value.split(',')
    when '--indir'
      infiles << read_infiles(value)
    when '--rast'
      rast_file = value
    when '--outdir'
      outdir = value
    when '--cpu'
      $cpu = value.to_i
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
  end
end


####################################################
infiles.flatten!

mkdir_with_force(outdir, is_force, is_tolerate)


####################################################
rastInfo = readRastFile(rast_file)


####################################################
infiles.each do |infile|
  b = File.basename(infile)
  outdir2 = File.join(outdir, b)
  mkdir_with_force(outdir2)

  gained, no, lost, prior, after = getGainedLost(infile)

  final = multi_D_Hash(5)
  [:fam, :gene].each do |type|
    final = getFinal(gained[type], type, final, :gained, rastInfo)
    final = getFinal(no[type], type, final, :no, rastInfo)
    final = getFinal(lost[type], type, final, :lost, rastInfo)
    final = getFinal(prior[type], type, final, :prior, rastInfo)
    final = getFinal(after[type], type, final, :after, rastInfo)
  end

  [:fam, :gene].each do |type|
    outdir3 = File.join(outdir2, type.to_s)
    mkdir_with_force(outdir3)
    outputFinal(final, type, outdir3)
  end
end


