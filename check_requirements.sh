#! /bin/bash


####################################################
dir=`dirname $0`


####################################################
source $dir/check_which.sh


####################################################
echo "Checking required programs ......"
check_which ruby python
echo

echo "Checking required libraries for RUBY ......"
ruby $dir/checkRubyPackages.rb
echo

