#!/usr/bin/env python3
import argparse
import contextlib
import csv
import http.client
import os

#This script assigns enzyme names to enzyme identifiers using the ExploreEnz database.
#Here, we are only using the data containing enzymes that are differentially abundant in response to nematode addition.


# ### Parse the arguments from the command line

# Define what should be the arguments from the command line
parser = argparse.ArgumentParser(description='Creates an output file that will contain the data from the input file + extra columns for enzyme names and reactions retrieved from ExploreEnz enzyme database. Additionally, an output folder with the same name as the output file (minus file extension) containing an HTML page per enzyme will be created.')
parser.add_argument('input_file_name',
                    help='the input file. For example, "DATA_kegg_enzymes_unique_T1nematodes_Vs_T0control2.tsv"')
parser.add_argument('output_file_name',
                    help='the output file. For example, "DATA_kegg_enzymes_unique_names_reactions_T1nematodes_Vs_T0control2.tsv"')

# Parse the arguments from the command line
args = parser.parse_args()


# ### Go through the input file and add enzyme names and reactions columns from database, and store the other data to the output folder:

# Create the output folder if it doesn't exist yet
output_folder_name = os.path.splitext(args.output_file_name)[0]
try:
    os.mkdir(output_folder_name)
except FileExistsError:
    pass    # ignore error when folder already exists

# Define a function to find data inbetween a left and a right part of the given input data
def find_inbetween(inp, left, right):
    left_index = inp.find(left)
    assert left_index != -1, "Unable to find left part " + repr(left) + " in input data " + repr(inp)
    found_index = left_index + len(left)
    right_index = inp.find(right, found_index)
    assert right_index != -1, "Unable to find right part " + repr(right) + " in input data " + repr(inp)
    return inp[found_index:right_index]

DATABASE_SERVER = "www.enzyme-database.org"
DATABASE_QUERY_FORMATTER = lambda enzyme: "/query.php?ec=" + enzyme + "&pr=on"
DATABASE_RESPONSE_DATA_ENZYME_NAME_PARSER = lambda data: find_inbetween(data, left=b'  <tr>\n    <td width="20%" align="right"><strong>Accepted&nbsp;name:</strong></td>\n    <td width="80%" colspan="1">', right=b'</td>\n  </tr>\n').decode("utf-8")
DATABASE_RESPONSE_DATA_REACTIONS_PARSER = lambda data: find_inbetween(data, left=b'  <tr>\n    <td width="20%" align="right"><strong>Reaction:</strong></td>\n    <td width="80%" colspan="1">', right=b'</td>\n  </tr>\n').decode("utf-8")

# Define a convenience function to print and return "N/A" upon parsing error, and otherwise return the parsed content
def na_on_parse_error(enzyme, item_name, item_parser, enzyme_data):
    try:
        return item_parser(enzyme_data)
    except Exception as exception:
        print("Failed to parse " + item_name + " from database for enzyme " + enzyme + ": " + str(exception))
        return "N/A"

# Define a context manager for http.client.HTTPSConnection to make it safer to automatically close the connection at the end
@contextlib.contextmanager
def open_https_connection(server):
    connection = http.client.HTTPSConnection(server)
    try:
        yield connection
    finally:
        connection.close()

input_file_enzyme_column = None    # not yet known; this will be known as soon as we have parsed the header
INPUT_FILE_ENZYME_COLUMN_NAME = "enzyme"

output_file_enzyme_name_column = None    # not yet known; this will be known as soon as we have parsed the header
OUTPUT_FILE_ENZYME_NAME_COLUMN_NAME = "enzyme.name"
output_file_reactions_column = None    # not yet known; this will be known as soon as we have parsed the header
OUTPUT_FILE_REACTIONS_COLUMN_NAME = "reactions"

# Open the input file with read ('r') access, and create a TSV (Tab Separated Value) reader for it
with open(args.input_file_name, 'r', newline='') as input_file:
    tsv_reader = csv.reader(input_file, delimiter='\t')

    # Open the output file  with write ('w') access, and create a TSV (Tab Separated Value) writer for it
    with open(args.output_file_name, 'w', newline='') as output_file:
        tsv_writer = csv.writer(output_file, delimiter='\t')

        # Open a connection with the database
        with open_https_connection(DATABASE_SERVER) as database_connection:

            # For each row of our input file, we'll store a row to either output_file_header_row or output_file_enzyme_id_to_rows
            for row_index, row in enumerate(tsv_reader):
                # Process the first row, which is a header
                if row_index == 0:
                    # Search for the enzyme column
                    input_file_enzyme_column = row.index(INPUT_FILE_ENZYME_COLUMN_NAME)

                    # Add "enzyme.name" and "reactions" as extra columns to the current row, just after the enzyme column
                    output_file_enzyme_name_column = input_file_enzyme_column + 1
                    output_file_reactions_column = input_file_enzyme_column + 2
                    row.insert(output_file_enzyme_name_column, OUTPUT_FILE_ENZYME_NAME_COLUMN_NAME)
                    row.insert(output_file_reactions_column, OUTPUT_FILE_REACTIONS_COLUMN_NAME)

                # Process the other rows
                else:
                    # Get the enzyme from our input file
                    enzyme = row[input_file_enzyme_column]

                    # Using our enzyme, query the database to get the extra data
                    database_connection.request(method="GET", url=DATABASE_QUERY_FORMATTER(enzyme))
                    database_response = database_connection.getresponse()
                    if database_response.status == http.HTTPStatus.OK:
                        enzyme_data = database_response.read()
                    else:
                        enzyme_data = None
                        print("Failed to retrieve data from database for enzyme " + enzyme + ": " + database_response.reason)

                    # Write the data to the output folder, if there is data
                    if enzyme_data is not None:
                        enzyme_data_file_name = os.path.join(output_folder_name, enzyme + ".html")
                        with open(enzyme_data_file_name, 'wb') as enzyme_data_file:
                            enzyme_data_file.write(enzyme_data)

                    # Try to parse the enzyme name and reactions from the enzyme data (if it exists) and store "N/A" on error
                    if enzyme_data is not None:
                        enzyme_name = na_on_parse_error(enzyme, "enzyme name", DATABASE_RESPONSE_DATA_ENZYME_NAME_PARSER, enzyme_data)
                        reactions = na_on_parse_error(enzyme, "reactions", DATABASE_RESPONSE_DATA_REACTIONS_PARSER, enzyme_data)
                    else:
                        enzyme_name = "N/A"
                        reactions = "N/A"

                    # Add these as two extra columns to the current row
                    row.insert(output_file_enzyme_name_column, enzyme_name)
                    row.insert(output_file_reactions_column, reactions)

                # Write the header row to the output file
                tsv_writer.writerow(row)

                # Report progress
                print("Processed row " + str(1 + row_index))
