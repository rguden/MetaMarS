#!/usr/bin/bash
#Rodgee Mae Guden
#rodgeemae.guden@ugent.be
#This bash script can be used to perform functional analyses for RNA-seq data from metatranscriptomics datasets using COG (Cluster of Orthologous Genes).
#Prior steps: fastqc - cutadapt - PEAR - sortmerna 
#The steps in this script are:
#   1.   Converting fastq to fasta.
#   2.   Translating the read sequences to amino acids using FragGeneScan.
#   3.   Blasting the query proteins with RPS-BLAST+ against NCBI's Conserved Domain Database (CDD).
#   4.   Assigning COG (cluster of orthologous groups) categories to proteins.
#   5.   Combining the cog outputs of all samples into one count table. 

#inputs: non-rRNA_merged + non-rRNA_forward

#set the working directory
DIR="/media/HD3/home/rguden/Documents/RNA/Functional_analysis/mrna/final"
#set the directory for input files
INPUT_DIR="$DIR/sequences"
#set the directory for output files
OUT_DIR="$DIR/output_files"
STEP_1="$OUT_DIR/step_1_output"
STEP_2="$OUT_DIR/step_2_output"
STEP_3="$OUT_DIR/step_3_output"
STEP_4="$OUT_DIR/step_4_output"

mkdir -p "$OUT_DIR"

date
echo

#Step 1:Converting fastq to fasta
#Make a new directory inside the output directory where the results for this step will be saved
mkdir -p "$STEP_1"

echo "Converting fastq to fasta..."

#Command for all files in the $INPUT_DIR directory
for fin in ${INPUT_DIR}/*.fastq; do
    filename="${fin##*/}"    # e.g., "/path/to/file.v1.txt" becomes "file.v1.txt"
    filename_without_extension="${filename%.[^.]*}"    # e.g., "file.v1.txt" becomes "file.v1"
    fout="$STEP_1/${filename_without_extension}.fasta"
    #command
    sed -n '1~4s/^@/>/p;2~4p' "$fin" > "$fout"
done
echo "Done converting fastq to fasta."
echo

#Step 2: Translating the read sequences to amino acids using FragGeneScan
#Make a new directory inside the output directory where the results for this step will be saved
mkdir -p "$STEP_2"

echo "Translating the read sequences to amino acids..."

#Command for all files in the $STEP_1 directory
#Generate output files with extensions: .out , .ffn , .faa , .gff
#-out=  : specify filenames prefix
for fin in ${STEP_1}/*.fasta; do
    filename="${fin##*/}"    # e.g., "/path/to/file.v1.txt" becomes "file.v1.txt"
    filename_without_extension="${filename%.[^.]*}"    # e.g., "file.v1.txt" becomes "file.v1"
    fout="$STEP_2/${filename_without_extension}.fgs"
    #command
    run_FragGeneScan.pl \
        -genome="$fin" \
        -out="$fout"   \
        -complete=0   \
        -train=illumina_5 \
        -thread=12
done
echo "Done translating the read sequences to amino acids."
echo

#Step 3: Blasting the query proteins with RPS-BLAST+
#Make a new directory inside the output directory where the results for this step will be saved
mkdir -p "$STEP_3"
    
echo "Blasting the query proteins..."

#set the path for the COG database:
COG_DB="/media/HD3/home/rguden/Documents/RNA/Functional_analysis/Cog_db/Cog"

#Command for all files in the $STEP_2 directory
#input: <file>.faa
#generate output file with extension: .rpsblast.out
for fin in ${STEP_2}/*.fgs.faa; do
    filename="${fin##*/}"    # e.g., "/path/to/file.v1.txt" becomes "file.v1.txt"
    filename_without_extension="${filename%.[^.]*}"    # e.g., "file.v1.txt" becomes "file.v1"
    fout="$STEP_3/${filename_without_extension}.fgs.faa.rpsblast.out"
    #command
    rpsblast \
        -query "$fin" \
        -db  "$COG_DB" \
        -out "$fout" \
        -evalue 0.001 \
        -outfmt 6 \
        -num_threads 12
done
echo "Done blasting the query proteins."
echo

#Step 4: Assigning COG (cluster of orthologous groups) categories to proteins
#cddcog.pl script: Leimbach A. 2016. bac-genomics-scripts: Bovine E. coli mastitis comparative genomics edition. Zenodo. http://dx.doi.org/10.5281/zenodo.215824.

#Make a new directory inside the output directory where the results for this step will be saved

echo "Assigning COG categories to proteins..."

#set the paths to cddcog.pl script, cddid.tbl, fun.txt, and whog
    #cddid.tbl: contains summary information about the CD models in a tab-delimited format. The columns are: PSSM-Id, CD accession (e.g. COG#), CD short name, CD description, and PSSM (position-specific scoring matrices) length.
    #fun.txt: one-letter functional classification used in the COG database.
    #whog: name, description, and corresponding functional classification of each COG.
CDD2COG="/media/HD3/home/rguden/Documents/RNA/Functional_analysis/mrna/Cdd2cog/cdd2cog.pl"
CDDID="/media/HD3/home/rguden/Documents/RNA/Functional_analysis/mrna/Cdd2cog/cddid.tbl"
FUN="/media/HD3/home/rguden/Documents/RNA/Functional_analysis/mrna/Cdd2cog/fun.txt"
WHOG="/media/HD3/home/rguden/Documents/RNA/Functional_analysis/mrna/Cdd2cog/whog"

#Command for all files in the $STEP_3 directory
#Input: <file>.rpsblast.out
#Outputs
    #./results: all tab-delimited output files are stored in this result folder
    #rps-blast_cog.txt: COG assignments concatenated to the RPS-BLAST+ results for filtering
    #protein-id_cog.txt: slimmed down 'rps-blast_cog.txt' only including query id (first BLAST report column), COGs, and functional categories
    #cog_stats.txt: assignment counts for each used COG
    #func_stats.txt: assignment counts for single-letter functional categories
    
for fin in ${STEP_3}/*.rpsblast.out; do
    filename="${fin##*/}"    # e.g., "/path/to/file.v1.txt" becomes "file.v1.txt"
    #command
    perl "$CDD2COG" \
        -r "$fin" \
        -c "$CDDID" \
        -f "$FUN" \
        -w "$WHOG" \
        
done
echo "Done assigning COG categories to query proteins."
echo

date

#Step 5: Combining the cog outputs of all samples into one count table.
#The "cog_outputs" folder contains the results of the previous steps.

cd cog_outputs
../join_cogs.py
cd ..
