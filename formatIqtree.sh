#! /bin/bash


#########################################################################
dir=`dirname $0`


#########################################################################
suffix=ufboot
changeGeneName=$dir/changeGeneName.rb
n=100


#########################################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--suffix)
			suffix=$2
			shift
			;;
		-n)
			n=$2
			shift
			;;
	esac
	shift
done


#########################################################################
for i in `find $indir -name "*$suffix"`; do
	b=`basename $i`;
	c=${b%.$suffix};
	echo $c
	mkdir $outdir/$c -p;
	ruby $changeGeneName -i $i -n $n > $outdir/$c/$c.bootstrap.trees;
	#head $i -n $n > $outdir/$c/$c.bootstrap.trees;
done


