#! /usr/bin/env python


##############################################################
import sys
import imp


##############################################################
module_dict = {}
modules = ['matplotlib', 'numpy', 'mpl_toolkits']
for module in modules:
    module_dict[module] = ''


##############################################################
for index, module in enumerate(modules):
    try:
        imp.find_module(module)
    except ImportError, e:
        print >>sys.stderr, "Module %s has NOT been installed!" % module
    else:
        print "Module %s is installed." % module


