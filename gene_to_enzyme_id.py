#!/usr/bin/python3
import argparse
import csv
import sys

#This script assigns enzyme identifiers to annotated prokka genes.
#This adds "N/A" to Prokka genes that do not have corresponding enzyme IDs

# ### Parse the arguments from the command line

# Define what should be the arguments from the command line
parser = argparse.ArgumentParser(description='Creates an output file that will contain the data from the input file + extra column for enzyme ID.')
parser.add_argument('gene_to_enzyme_file_name',
                    help='the gene file (with gene names and enzyme IDs). Here the file is called "PROKKA_05072021.all.assembled.ec"')
parser.add_argument('input_file_name',
                    help='the input file (with gene names and counts) after performing featureCounts. Here the file is called "CountTable_CLC_Gene.tsv"')
parser.add_argument('output_file_name',
                    help='the output file. This will add enzyme IDs to the PROKKA genes. Here the file is called "gene_to_enzyme_id.tsv"')

# Parse the arguments from the command line
args = parser.parse_args()



# ### Create dictionary with: gene -> enzyme

gene_to_enzyme_dictionary = {}

GROUP_FILE_GENE_COLUMN = 0    
GROUP_FILE_ENZYME_COLUMN = 1    

# Open the 'gene to enzyme file' with read ('r') access, and create a TSV (Tab Separated Value) reader for it
with open(args.gene_to_enzyme_file_name, 'r', newline='') as gene_to_enzyme_file:
    tsv_reader = csv.reader(gene_to_enzyme_file, delimiter='\t')

    # For each row of our 'gene to enzyme file', we'll save some data to our dictionary
    for row in tsv_reader:
        # Get the gene and enzyme from our 'gene to enzyme file'
        gene = row[GROUP_FILE_GENE_COLUMN]
        enzyme = row[GROUP_FILE_ENZYME_COLUMN]

        # We add this data as a new item to our dictionary: gene -> enzyme
        gene_to_enzyme_dictionary[gene] = enzyme


# ### Go through the "CountTable_GeneToEnzyme.tsv" file and add one column

OUTPUT_FILE_GENE_COLUMN = 0    

# Open the input file with read ('r') access, and create a TSV (Tab Separated Value) reader for it
with open(args.input_file_name, 'r', newline='') as input_file:
    tsv_reader = csv.reader(input_file, delimiter='\t')

    # Open the output file  with write ('w') access, and create a TSV (Tab Separated Value) writer for it
    with open(args.output_file_name, 'w', newline='') as output_file:
        tsv_writer = csv.writer(output_file, delimiter='\t')

        # For each row of our input file, we'll write a row to our output file
        for row_index, row in enumerate(tsv_reader):
            # Process the first row, which is a header
            if row_index == 0:
                # Add "enzyme ID" as an extra column to the current row, just after the gene column
                row.insert(OUTPUT_FILE_GENE_COLUMN + 1, "enzyme ID")
            
            # Process the other rows
            else:
                # Get the gene from our input file ("CountTable_GeneToEnzyme.tsv")
                gene = row[OUTPUT_FILE_GENE_COLUMN]

                # Using our gene, get the enzyme from our dictionaries
                if gene in gene_to_enzyme_dictionary:
                    enzyme = gene_to_enzyme_dictionary[gene]
                else:
                    enzyme = "N/A"

                # Add this as an extra column to the current row, just after the gene column
                row.insert(OUTPUT_FILE_GENE_COLUMN + 1, enzyme)

            # Write the updated row to the output file
            tsv_writer.writerow(row)
