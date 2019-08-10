#! /bin/bash


#######################################################
# wrapperAngst
# Author: Sishuo Wang from Haiwei Luo Lab at Chinese University of Hong Kong
# E-mail: sishuowang@hotmail.ca sishuowang@cuhk.edu.hk
# Last updated: 2018-04-18
# Copyright: CC 4.0 (https://creativecommons.org/licenses/by/4.0/)
# Version 2.1
# Major updates
# 1. Several scripts to summarize output from Badirate has been included.
# 2. OK to count gene gains/losses by a single gene for AnGST.
#
#
# Version: 1.3
# Major updates:
# 1. using multiple processes for transformation of gene trees allowed
# 
# Summary of updates of older versions
# Version: 1.2
# 1. mapping gene/family count to species phylogeny
# 2. tree file format conversion optimized
#
#
# This script and associated scripts are designed for gene gain/loss analysis with AnGST
# Goals:
#	1. finding the parameters that minimize the genome flux size
#	2. running AnGST
#
# Please be aware that you might need to cite related papers when using this script.
# Please see the usage by '-h' for details.


#######################################################
dir=`dirname $0`
source $dir/check_which.sh


echo "Please note that the license has been changed to CC 4.0 (https://creativecommons.org/licenses/by/4.0/) since version 1.2."
echo -e "Please be aware that \e[0;1;31mthe gene locus of Agrobacterium_fabrum_str_C58 is named in a different from other taxa.\e[0m"

echo "Checking requirements ......"
if bash $dir/check_requirements.sh | grep NOT; then
	usage
else
	echo -e "Great! You seem to have everything installed.\n"
fi


#######################################################
transformGeneTree=$dir/transformGeneTree.rb
transformGeneTree_inBatch=$dir/transformGeneTree_inBatch.rb
runAngst_inParallel=$dir/runAngst_inParallel.rb
findBestParamAngst=$dir/findBestParamAngst.rb
plot3d=$dir/plottingGenomeFluxSize3d.py


angst=~/software/phylo/angst/angst_lib/AnGST.py
indir=''
outdir=''
species_tree_file=''
hgt='0,9'
dup='0,9'
los='1,1'
cpu=1
range_cmd=''
is_subtree=''
is_ultrametric=''
is_plot=false
is_force=false


#######################################################
function usage(){
	echo -e "wrapperAngst.sh: a wrapper script to run AnGST analysis."
	echo 'Usage:'
	echo 'Mandantory arguments:'
	echo '<--indir>'
	echo '<--outdir>'
	echo '<-s|--species_tree>'
	echo -e '\e[0;1;31mImportant: please make sure to replace the original "AnGSTInput.py" with the one with the same name provided along with this tool.\e[0m'
	echo -e 'Important: please also make sure that in the indir, the tree file can be found in the path \e[0;1;34mindir/gene/gene.bootstrap.trees\e[0m'
	echo
	echo 'Optional arguments'
	echo -e '--angst\tthe path to AnGST.py'
	echo -e '--hgt\tpenalty for horizontal gene transfer (default:0,9)'
	echo -e '--dup\tpenalty for gene duplication (default:0,9)'
	echo -e "--los\tpenalty for gene loss (default:1,1)"
	echo -e "--range\trange from. Format: 51-100 or 51,100 (default:off)"
	echo -e "--cpu\tnumber of cpu to use (default:1)"
	echo -e "--subtree\tto perform ANGST analysis using the subtree when applied (default:off)"
	echo -e "--ultrametric\tto perform ANGST analysis using the tree that represents time (default:off)"
	echo -e "--plot\tplot the distribution of genome flux size (z) with x and y as the penalty of HGT and gene loss, respectively (default:off)"
	echo -e "--force\tremove the outdir if it exists"
	echo -e "-h\tprint usage"
	echo
	echo 'Please cite the following papers in case you feel that this tool is helpful.'
	echo -e "1. Lawrence A. David and Eric J. Alm. Rapid evolutionary innovation during an Archean Genetic Expansion. Nature 469, 93-96 (2011)."
	echo -e "2. Goto, N. et al. BioRuby: bioinformatics software for the Ruby programming language. Bioinformatics 26, 2617-2619 (2010)."
	echo
	echo "This script is distributed under CC 4.0 License and in the hope that it can be useful, but WITHOUT ANY WARRANTY."
	echo "For any question or bug report, please contact Sishuo Wang at Haiwei Luo Lab, Chinese University of Hong Kong via e-mail (sishuowang@hotmail.ca or sishuowang@cuhk.edu.hk). Your help is highly appreciated."
	exit 1
}


#######################################################
[ $# -eq 0 ] && usage

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
		-s|--species_tree)
			species_tree_file=$2
			shift
			;;
		--angst)
			angst=$2
			shift
			;;
		--hgt)
			hgt=$2
			shift
			;;
		--dup)
			dup=$2
			shift
			;;
		--los)
			los=$2
			shift
			;;
		--cpu)
			cpu=$2
			shift
			;;
		--range)
			range_cmd="--range $2"
			shift
			;;
		--subtree)
			is_subtree='--subtree'
			;;
		--ultrametric)
			is_ultrametric='--ultrametric'
			;;
		--plot)
			is_plot=true
			;;
		--force)
			is_force=true
			;;
		-h|--h|--help)
			usage
			;;
		*)
			echo -e "illegal params:\t$1"
			usage
			;;
	esac
	shift
done


#######################################################
if [ ! -f $angst ]; then
	echo "AnGST.py does not exist. Please specify it using --angst." >&2
	usage
fi


#######################################################
if [ -d $outdir ]; then
	if [ $is_force == false ]; then
		echo "The outdir $outdir has already existed. You could use --force to remove it. Exiting ......" >&2
		exit 1
	else
		rm -rf $outdir
	fi
fi

mkdir -p $outdir
new_species_tree_file=$outdir/species.tree
species_tree_rela=$outdir/species.rela
tree_dir=$outdir/tree
angst_dir=$outdir/angst
genomeFluxSizeTbl=$outdir/genomeFluxSize.tbl

for i in tree_dir angst_dir; do
	eval k=\$$i
	mkdir -p $k
done


#######################################################
echo "Transforming gene tree and species tree ......"
ruby $transformGeneTree -s $species_tree_file --output_species_tree | sed '$d' | sed 's/ /_/g' > $species_tree_rela
ruby $transformGeneTree -s $species_tree_file --output_species_tree | tail -1 > $new_species_tree_file
ruby $transformGeneTree_inBatch --indir $indir --outdir $tree_dir -s $species_tree_file --force --cpu $cpu $range_cmd
[ $? -ne 0 ] && echo "Transformation failed! Exiting" && exit 1


echo "Running AnGST in parallel with $cpu cores. This step costs much time. Please be patient."
ruby $runAngst_inParallel --angst $angst --indir $tree_dir --outdir $angst_dir -s $new_species_tree_file --tolerate --cpu $cpu --hgt $hgt --dup $dup --los $los $is_subtree $is_ultrametric


echo
echo "Finding best parameters for AnGST ......"
ruby $findBestParamAngst --indir $angst_dir -s $new_species_tree_file | sort -t '-' -nk1 -nk2 -nk3 > $genomeFluxSizeTbl
a=`sort -nk2 $genomeFluxSizeTbl | head -1`
echo -e "The parameters that minimize genome flux size is:\t\033[31m$a\033[0m"


# Optional
# Please note that by default that the penalty of gene loss should be the same for all combinations. Please feel free to edit the following scripts in case there is any problem.
if [ $is_plot == true ]; then
	if python $dir/checkPythonPackages.py | grep NOT; then
		echo "Sorry, please install the required modules in order to do plotting. Exiting ......" >&2
		exit 1
	fi
	echo "Plotting ......"
	python $plot3d -i $genomeFluxSizeTbl -o $outdir/genomeFluxSize3d.pdf
fi


