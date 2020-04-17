#!/usr/bin/python

####################################################################################################################################
# Author: Christophe Verwimp, P21, Growth & Development
# Contact: christophe.verwimp@ilvo.vlaanderen.be
# Version: 1
# Date: 10/09/2015
#
# This script counts number of reads in FastQ file.
#
# This script requires:
#			- Python 2.7.6
#
# Usage:	python FastQ_CountReads.py -i (or --fastq) myFastQ
#
# This script is used in the workflows of GBS for Mnemiopsis and Lolium.
####################################################################################################################################

import sys, getopt

# Accepting arguments.

try:
	opts, args = getopt.getopt(sys.argv[1:], 'i:' , ['fastq=', ])
except getopt.GetoptError as err:
	# Print help information and exit.
	print str(err)
	sys.exit(2)
for opt, arg in opts:
	if opt in ('-i', "--fastq"):
		FastQ = arg

# Counting available reads

with open(FastQ) as input:
	NumberOfLines = sum([1 for line in input])
	if NumberOfLines % 4 == 0:
		print(int(NumberOfLines / 4))
	else:
		print("ERRORR, FastQ file corrupt, number of lines must be a multiple of 4")