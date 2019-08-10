#! /usr/bin/env python


# 3D.py
# Author: Sishuo Wang from Chinese University of Hong Kong
# New BSD License


#####################################################################
import sys
import random
import getopt


from matplotlib import pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import Axes3D


#####################################################################
infile = None
outfile = None


#####################################################################
opts, args = getopt.getopt(
    sys.argv[1:],
    "i:o:",
    ["in=","out="],
)


for opt, arg in opts:
    if opt == '-i' or opt == '--in':
        infile = arg
    elif opt == '-o' or opt == '--out':
        outfile = arg
    else:
        print >>sys.stderr, "Wrong argument %s! Exiting ......" % opt
        sys.exit(1)


#####################################################################
def readInfile(infile):
    np_info = {}
    for i in ['X', 'Y', 'Z']:
        np_info[i] = []

    try:
        in_fh = open(infile, 'r')
    except IOError:
        raise Exception("infile %s cannot be opened!" % infile)

    for line in in_fh.readlines():
        line = line.strip('\n\r')
        cat, noOfGenes = line.split('\t')
        noOfGenes = int(noOfGenes)
        cat_arr = map(lambda x: int(x), cat.split('-'))
        if not cat_arr[0] in np_info['X']:
            np_info['X'].append(cat_arr[0])
        if not cat_arr[1] in np_info['Y']:
            np_info['Y'].append(cat_arr[1])
        np_info['Z'].append(noOfGenes)
    in_fh.close()
    return(np_info)


#####################################################################
np_info = readInfile(infile)


#####################################################################
fig = plt.figure()
ax = Axes3D(fig)


X = np.array(np_info['X'])
Y = np.array(np_info['Y'])
Z = np.array(np_info['Z'])

X, Y = np.meshgrid(X, Y)
Z = np.array(Z).reshape(len(np_info['X']), len(np_info['Y']))

#print X
#print Y
#print Z

ax.plot_surface(X, Y, Z, rstride=1, cstride=1, cmap='rainbow')

if outfile:
    plt.savefig(outfile)
else:
    plt.show()


