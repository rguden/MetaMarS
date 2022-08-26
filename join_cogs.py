#!/usr/bin/env python
#Rodgee Mae Guden
#rodgeemae.guden@ugent.be

#This scripts allows combining the cog outputs of all samples into one count table.
#This creates a non-redundant list of COGs that have been oberved at least once in at least one of the samples, and takes the sum of counts for duplicated COGs per sample.

import os


# Define all file names
inputFileNames = sorted([f for f in os.listdir(".") if f.endswith(".txt")])
outputFileName = "all_cogs.tsv"


# Open output file for writing
outputFile = open(outputFileName, 'w')

# Write header
header = "Function Name\t" + "\t".join(inputFileNames)
outputFile.write(header + "\n")

# Read data
allData = {}
allFuncNames = set()
for f in inputFileNames:
    data = {}
    content = open(f, 'r').read()
    for line in content.split("\n")[:-1]:
        fields = line.split("\t")
        funcName = fields[1]
        count = int(fields[2])
        if funcName in data:
            data[funcName] = data[funcName] + count
        else:
            data[funcName] = count
        allFuncNames.add(funcName)
    allData[f] = data

# Write data
for funcName in sorted(allFuncNames):
    allCounts = []
    for f in inputFileNames:
        data = allData[f]
        if funcName in data:
            allCounts.append(str(data[funcName]))
        else:
            allCounts.append("0")
    
    line = funcName + "\t" + "\t".join(allCounts)
    outputFile.write(line + "\n")
