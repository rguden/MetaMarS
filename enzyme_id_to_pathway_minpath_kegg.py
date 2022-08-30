#!/usr/bin/python3
import argparse
import csv
import sys

#This script assigns pathways names to enzyme identifiers based on the KEGG database.

# ### Parse the arguments from the command line

# Define what should be the arguments from the command line
parser = argparse.ArgumentParser(description='Creates an output file that will contain the data from the input file + extra columns for group letters and group names.')
parser.add_argument('enzyme_to_pwy_file_name',
                    help='the enyzme to pathway file (with pathway ID, enzyme ID, and pathway name). Typically, this file is called "ec.to.pwy.txt"')
parser.add_argument('pwy_to_hierarchy_file_name',
                    help='the pathway to hierarchy file (with pathway number and pathway category). Typically, this file is called "pwy.hierarchy"')
parser.add_argument('minpath_file_name',
                    help='the output file after minpath. This contains the minimum predicted metabolic pathways in the samples with their pathway IDs. Typically, this file is called "PROKKA_05072021.all.assembled.ec.kegg.minpath"')
parser.add_argument('input_file_name',
                    help='the count table file with all samples, gene name and enzyme ID (without pathway ID, pathway name, and pathway category). Here, this file is called "gene_to_enyzme_id.tsv."')
parser.add_argument('output_file_name',
                    help='the output file with gene name, enzyme ID, pathway ID, pathway name, and pathway category. Typically, this file is called  "enzyme_id_to_pathway_minpath_kegg.tsv"')

# Parse the arguments from the command line
args = parser.parse_args()



# ### Create dictionary with: enyzme ID -> pathway id

enzyme_to_pathway_name_dictionary = {}
enzyme_to_pathway_id_dictionary = {}

GROUP_FILE_PATHWAY_ID_COLUMN = 0 
GROUP_FILE_ENZYME_ID_COLUMN = 1    

# Open the 'group file' with read ('r') access, and create a TSV (Tab Separated Value) reader for it
with open(args.enzyme_to_pwy_file_name, 'r', newline='') as enzyme_to_pwy_file:
    tsv_reader = csv.reader(enzyme_to_pwy_file, delimiter='\t')

    # For each row of our 'enzyme_to_pwy_file', we'll save some data to our dictionary
    for row in tsv_reader:
        # Get the enzyme id, pathway name and pathway id from our 'enzyme_to_pwy file'
        group_file_enzyme_id = row[GROUP_FILE_ENZYME_ID_COLUMN]
        group_file_pathway_id = row[GROUP_FILE_PATHWAY_ID_COLUMN]
        # We add this data as a new item to our dictionary: group_letter -> group_name
        enzyme_to_pathway_id_dictionary[group_file_enzyme_id] = group_file_pathway_id


# ### Create dictionary with: pathway_id -> pathway_categories

pathway_id_to_pathway_categories_dictionary = {}

PWY_TO_HIERARCHY_FILE_PATHWAY_ID_COLUMN = 0    
PWY_TO_HIERARCHY_FILE_PATHWAY_CATEGORY_COLUMNS_START = 1    

# Open the 'pwy to hierarchy file' with read ('r') access, and create a TSV (Tab Separated Value) reader for it
with open(args.pwy_to_hierarchy_file_name, 'r', newline='') as pwy_to_hierarchy_file:
    tsv_reader = csv.reader(pwy_to_hierarchy_file, delimiter='\t')

    # For each row of our 'pwy_to_hierarchy_file', we'll save some data to our dictionary
    for row in tsv_reader:
        # Get the pathway ID and pathway categories from our 'pwy to hierarchy file'
        pwy_to_hierachy_file_pathway_id = row[PWY_TO_HIERARCHY_FILE_PATHWAY_ID_COLUMN]
        pwy_to_hierachy_file_pathway_categories = row[PWY_TO_HIERARCHY_FILE_PATHWAY_CATEGORY_COLUMNS_START:]

        # We add this data as a new item to our dictionary: pathway_id -> pathway_categories
        pathway_id_to_pathway_categories_dictionary[pwy_to_hierachy_file_pathway_id] = pwy_to_hierachy_file_pathway_categories


# ### Create set of pathway_id elements

pathway_ids_with_minpath_set = set()

MINPATH_FILE_MINPATH_NUMBER_COLUMN = 2
MINPATH_FILE_PATHWAY_ID_COLUMN = 8 

# Open the minpath file with read ('r') access
with open(args.minpath_file_name, 'r', newline='') as minpath_file:
    # For each row of our 'minpath_file_name', we'll save some pathway IDs to our set
    for line in minpath_file:
        # Skip empty lines (typically at the end of the file)
        if line == "":
            continue
        
        # Each row is formed by columns separated by two spaces (and we need to strip to remove the newline character at the end)
        row = line.strip().split("  ")
        
        # Get the minpath number and pathway ID from our minpath file
        minpath_number = row[MINPATH_FILE_MINPATH_NUMBER_COLUMN]
        pathway_id = row[MINPATH_FILE_PATHWAY_ID_COLUMN]

        # We add this pathway ID as a new item to our set in case the minpath number is 1
        if minpath_number == "minpath 1":
            pathway_ids_with_minpath_set.add(pathway_id)


# ### Go through the gene_to_enyzme_output.tsv file
#     and store the rows to be written later to the output file in output_file_header_row and output_file_pathway_id_to_rows.
#     The column with gene IDs will be removed
#     and the rows with the same enzyme ID will be collapsed into one row where the sample counts will be summed up across the rows.
#     Later we will write the contents of output_file_header_row and output_file_pathway_id_to_rows to the output file, but not now.

INPUT_FILE_GENE_ID_COLUMN = 0
INPUT_FILE_ENZYME_ID_COLUMN = 1

OUTPUT_FILE_ENZYME_ID_COLUMN = 0
OUTPUT_FILE_PATHWAY_ID_COLUMN = 1
OUTPUT_FILE_PATHWAY_CATEGORY_COLUMNS_START = 2
OUTPUT_FILE_PATHWAY_CATEGORY_NUMBER_OF_COLUMNS = max(len(pathway_categories)
                                                     for pathway_categories in pathway_id_to_pathway_categories_dictionary.values())
OUTPUT_FILE_SAMPLE_COUNT_COLUMNS_START = OUTPUT_FILE_PATHWAY_CATEGORY_COLUMNS_START + OUTPUT_FILE_PATHWAY_CATEGORY_NUMBER_OF_COLUMNS

output_file_header_row = None    # will contain a row with the columns of the header
output_file_pathway_id_to_rows = {}    # a dictionary from enzyme_id -> row

# Open the input file with read ('r') access, and create a TSV (Tab Separated Value) reader for it
with open(args.input_file_name, 'r', newline='') as input_file:
    tsv_reader = csv.reader(input_file, delimiter='\t')

    # For each row of our input file, we'll store a row to either output_file_header_row or output_file_pathway_id_to_rows
    for row_index, row in enumerate(tsv_reader):
        # Process the first row, which is a header
        if row_index == 0:
            # Delete the "gene ID" column
            del row[INPUT_FILE_GENE_ID_COLUMN]

            # Add "pathway ID", "pathway category <number>" as extra columns to the current row, just after the enzyme ID
            row.insert(OUTPUT_FILE_PATHWAY_ID_COLUMN, "pathway ID")
            for pathway_category_index in range(OUTPUT_FILE_PATHWAY_CATEGORY_NUMBER_OF_COLUMNS):
                row.insert(OUTPUT_FILE_PATHWAY_CATEGORY_COLUMNS_START + pathway_category_index, "pathway category %d" % (1 + pathway_category_index))

            # Store this updated row to be used later as header row for the output file
            output_file_header_row = row

        # Process the other rows
        else:
            # Get the enzyme from our input file ("gene_to_enyzme_output.tsv")
            enzyme = row[INPUT_FILE_ENZYME_ID_COLUMN]

            # Skip rows with no corresponding enzyme
            if enzyme not in enzyme_to_pathway_id_dictionary and enzyme != "N/A":
                continue

            # Using our enzyme ID, get the pathway ID and categories from our dictionaries
            if enzyme != "N/A":
                pathway_id = enzyme_to_pathway_id_dictionary[enzyme]
                pathway_categories = pathway_id_to_pathway_categories_dictionary[pathway_id]
            else:
                pathway_id = "N/A"
                pathway_categories = ["N/A"]

            # Mark rows that are not in the minpath set as N/A
            if pathway_id not in pathway_ids_with_minpath_set:
                pathway_id = "N/A"
                pathway_categories = ["N/A"]

            # Delete the gene ID
            del row[INPUT_FILE_GENE_ID_COLUMN]

            # Add these as extra columns to the current row, just after the enzyme ID
            row.insert(OUTPUT_FILE_PATHWAY_ID_COLUMN, pathway_id)
            for pathway_category_index in range(OUTPUT_FILE_PATHWAY_CATEGORY_NUMBER_OF_COLUMNS):
                # In case a certain enzyme has less pathway categories than the maximum amount of category columns, fill the remaining columns with empty strings
                pathway_category = pathway_categories[pathway_category_index] if pathway_category_index < len(pathway_categories) else ""
                row.insert(OUTPUT_FILE_PATHWAY_CATEGORY_COLUMNS_START + pathway_category_index, pathway_category)

            # Store the current row to be used later as a row for the output file.
            # If there's no row yet with this pathway_id in our dictionary, add the current row to our dictionary
            if pathway_id not in output_file_pathway_id_to_rows:
                output_file_pathway_id_to_rows[pathway_id] = row
            # Otherwise, lookup the existing row and add the sample counts of the current row to the sample counts of the existing row
            else:
                # Lookup the existing row
                existing_row = output_file_pathway_id_to_rows[pathway_id]

                # Add the sample counts of the current row to the sample counts of the existing row
                OUTPUT_FILE_SAMPLE_COUNT_COLUMNS_END = len(row)    # the sample count columns span till the end of the row
                for column_index in range(OUTPUT_FILE_SAMPLE_COUNT_COLUMNS_START, OUTPUT_FILE_SAMPLE_COUNT_COLUMNS_END):
                    existing_row[column_index] = str(int(existing_row[column_index]) + int(row[column_index]))


# ### Write the output file based on output_file_header_row and output_file_pathway_id_to_rows

# Open the output file with write ('w') access, and create a TSV (Tab Separated Value) writer for it
with open(args.output_file_name, 'w', newline='') as output_file:
    tsv_writer = csv.writer(output_file, delimiter='\t')

    # Write the header row to the output file
    tsv_writer.writerow(output_file_header_row)

    # For each pathway_name (sorted) in output_file_pathway_name_to_rows, we'll write the corresponding row to our output file
    for pathway_id in sorted(output_file_pathway_id_to_rows.keys()):
        # Look up the corresponding row
        row = output_file_pathway_id_to_rows[pathway_id]

        # Write the row to the output file
        tsv_writer.writerow(row)
