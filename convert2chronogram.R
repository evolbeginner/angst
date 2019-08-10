#! /usr/bin/env R


########################################################
library('ape')


########################################################
args <- commandArgs(trailingOnly = TRUE)

tree_file = args[1]


########################################################
tree <- read.tree(tree_file)

dendrogram <- chronos(tree)

write.tree(dendrogram)

