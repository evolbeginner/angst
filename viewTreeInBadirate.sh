#! /usr/bin/bash


#################################################################
grep $2 $1 | sed 's/^[^(]\+//' | nw_display -


