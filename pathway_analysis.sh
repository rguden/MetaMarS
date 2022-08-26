#!/usr/bin/bash
#Rodgee Mae Guden
#rodgeemae.guden@ugent.be
#This bash script can be used to perform functional analyses for RNA-seq data from metatranscriptomics datasets using the KEGG database to determine metabolic pathways.
#Prior step: de novo assembly of reads using CLC Workbench de novo assembler;
#The steps in this script are:
#   1.  Annotating the non-rRNA reads using Prokka.This program searches for open reading frames (ORFs) on contigs, translate ORFs to protein sequences, and assign enzyme identifiers to the coding regions.
#   2.  Extracting lists of Prokka genes that can be assigned with enzyme identifiers. 
#   3.  Converting the gff output of Prokka to a gtf file. 
#   4.  Mapping the original non-rRNA reads onto the assembly using Bowtie2, and sorting and indexing the resulting alignment files with SAMtools.
#   5.  Predicting metabolic pathways using Minpath. 
#   6.  Converting bam files to a count table
#   7.  Assigning enzyme identifiers to annotated prokka genes using the KEGG database.
#   8.  Assigning pathway names to enzyme identifiers using the KEGG database.

#inputs: non-rRNA_merged + non-rRNA_forward


#Step 1:Annotating the non-rRNA reads using Prokka.

step1_input_file="data/step_1_pathway/CLC_Genomics_Workbench_contigs1.fa"
step1_output_dir="data/step_1_pathway/output"

prokka $step1_input_file --outdir $step1_output_dir --cpus 16

#Step 2: Extracting the lists of Prokka genes that can be assigned with enzyme identifiers. 

step2_input_file="$step1_output_dir/PROKKA_07092021.gff"
step2_output_file="data/step_2_pathway/output/PROKKA_07092021.all.assembled.ec"

grep "eC_number=" $step2_input_file | cut -f9 | cut -f1,2 -d ';'| sed 's/ID=//g'| sed 's/;eC_number=/\t/g' > $step2_output_file

#Step 3:Converting the gff output of Prokka to a gtf file.

step2_input_file="$step1_output_dir/PROKKA_07092021.gff"
step3_output_file="data/step_3_pathway/output/PROKKA_07092021.gtf"

grep -v "#" $input_gff | grep "ID=" | cut -f1 -d ';' | sed 's/ID=//g' | cut -f1,4,5,7,9 |  awk -v OFS='\t' '{print $1,"PROKKA","CDS",$2,$3,".",$4,".","gene_id " $5}' > $step3_output_file

#Note: The resulting gtf file will be used to create a count table in R with the "featureCounts" function.

#Step 4: Mapping the original non-rRNA reads onto the assembly using Bowtie2, and sorting and indexing the resulting alignment files with SAMtools.

step4_infolder="/media/HD3/home/rguden/Documents/RNA/mrna/sequences"
step4_outfolder="data/step_4_pathway/output"

# remove the SAM intermediate and produce a sorted BAM
for fq in ${step4_infolder}/*.fastq; do
    filename="${fq##*/}" # e.g., "/path/to/file.v1.txt" becomes "file.v1.txt"
    filename_without_extension="${filename%.[^.]*}" # e.g., "file.v1.txt" becomes "file.v1"
	bowtie2 -p 16 -x $step1_input_file -U ${fq} | samtools sort -o $step4_outfolder/$filename_without_extension.bam -
	#echo ${fq}
done

#Note: The resulting BAM files will be used to create a count table in R with the "featureCounts" function.

#Step 5: Predicting metabolic pathways using Minpath.

#database
db_path_file="data/step_5_pathway/database_kegg/ec.to.pwy.kegg"
step5_outfolder="data/step_5_pathway/output"
results_kegg="$step5_outfolder/PROKKA_07092021.all.assembled.ec.kegg.minpath"
details_kegg="$step5_outfolder/PROKKA_07092021.all.assembled.ec.kegg.details"
log_kegg="$step5_outfolder/PROKKA_07092021.all.assembled.ec.kegg.log"

./MinPath1.2.py -any $step2_output_file -map $db_path_file -report $results_kegg -details $details_kegg

#Step 6: Converting bam files to a count table
#Execute "bam_to_count_table.R" R script.
step6_output_file="data/step_6_pathway/output/CountTable_CLC_Gene.tsv"

#Step 7: Assigning enzyme identifiers to annotated prokka genes using the KEGG database.

./gene_to_enzyme_id.py
step7_output_file="data/step_7_pathway/output/gene_to_enzyme_id.tsv"

#Step 8: Assigning pathway names to enzyme identifiers using the KEGG database.

./enzyme_id_to_pathway_minpath_kegg.py
step8_output_file="data/step_8_pathway/output/enzyme_id_to_pathway_minpath_kegg.tsv"



