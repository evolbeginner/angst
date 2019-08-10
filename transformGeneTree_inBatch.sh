#! /bin/bash


##################################################
dir=`dirname $0`
transformGeneTree=$dir/transformGeneTree.rb

source $dir/additional_script/processbar.sh


##################################################
is_force=false


##################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			;;
		--outdir)
			outdir=$2
			;;
		-s|--species_tree)
			species_tree_file=$2
			;;
		--force)
			is_force=true
			;;
	esac
	shift
done


if [ -d $outdir ]; then
	if [ $is_force == true ]; then
		rm -rf $outdir
	else
		echo "outdir has already existed! Exiting ......" >&2
		exit 1
	fi
fi
mkdir -p $outdir


##################################################
count=0
total=`ls -1 $indir | wc -l`
for subdir in $indir/*; do
	gene=`basename $subdir`
	mkdir $outdir/$gene
	for i in $subdir/*; do
		b=`basename $i`
		ruby $transformGeneTree -s $species_tree_file -g $i > $outdir/$gene/$b
		[ $? -ne 0 ] && exit 1
	done
	count=$((count+1))
	processbar $count $total
done
echo
echo "Transformation successfully done!"


