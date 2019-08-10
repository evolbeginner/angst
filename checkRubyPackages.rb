#! /usr/bin/env ruby


##############################################################
libs = Array.new
lib_dirs = Array.new


libs = %w[getoptlong bio tree parallel]
dir = File.dirname($0)
lib_dirs << File.join(dir, 'lib')


##############################################################
def add_lib_dirs(lib_dirs)
  lib_dirs.each do |lib_dir|
    $:.unshift lib_dir
  end
end


def check_lib(libs)
  lib_info = Hash.new
  libs.each do |lib|
    begin
      require lib
    rescue LoadError
      lib_info[lib] = false
    else
      lib_info[lib] = true
    end
  end
  return(lib_info)
end


def output_result(lib_info)
  lib_info.each_pair do |lib, true_or_false|
    case true_or_false
      when true
        #system("echo -e \"\e[0;1;31m#{lib}\e[0m is detected.\"")
        system("echo -e \"#{lib}\e[0m is installed.\"")
      when false
        system("echo -e \"\e[0;1;31m#{lib}\e[0m has NOT been installed.\"")
    end
  end
end


##############################################################
add_lib_dirs(lib_dirs)

lib_info = check_lib(libs)

output_result(lib_info)


