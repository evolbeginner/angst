#! /usr/bin/env python


#######################################################
import Bio
from Bio import Phylo
from ete3 import Tree


#######################################################
tree_file = "test_subtree/haha/species.tree"

tree = Phylo.read(tree_file, 'newick')

species_list = ['68', '90', '94', '96', '113', '116', '125']

lca = tree.common_ancestor(species_list)

Phylo.write(tree, '1.nwk', 'newick')

