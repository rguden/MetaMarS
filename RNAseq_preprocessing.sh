#!/bin/bash
# Annelies Haegeman 2020
# annelies.haegeman@ilvo.vlaanderen.be
# This bash script can be used to preprocess RNA-seq data from metatranscriptomics datasets.
# The steps done are quality check, adapter removal, merging of forward and reverse reads and rRNA sorting
# After the preprocessing, the resulting reads can be used for the Virusdetect pipeline.

#Specify here the folder where your samples are (in fastq.gz format):
DIR=/home/genomics/ALL_RAW_SEQ_DATA/10_Marine_microbial/Metatranscriptomics/18094-05
#Specify here the filepath to the FastQ_CountReads.py script
PYTHONSCRIPT="/home/genomics/ahaegeman/RNA-seq_sediment/FastQ_CountReads.py"

date
echo

# Change directory to specified folder
cd $DIR
# Initiate file with number of reads
echo -e "sample""\t""raw read pairs""\t""trimmed read pairs""\t""merged reads""\t""non rRNA merged reads" > Number_of_reads.txt

# Define the variable FILES that contains all the forward data sets (here only forward, otherwise you will do everything in duplicate!)
# When you make a variable, you can not use spaces! Otherwise you get an error.
FILES=( *_1.fq.bz2 )

#Loop over all files and do all the commands
for f in "${FILES[@]}" 
do 
	#Define the variable SAMPLE who contains the basename where the extension is removed (-1.fastq.gz)
	SAMPLE=`basename $f _1.fq.bz2`

	echo "PROCESSING $SAMPLE...."
	echo

	#MAKE DIRECTORY FOR THE SAMPLE
	mkdir $SAMPLE

	#QUALITY CHECK
	#echo "Checking quality for $SAMPLE...."
	#fastqc "$SAMPLE"_1.fq.bz2 -o $SAMPLE
	#fastqc "$SAMPLE"_2.fq.bz2 -o $SAMPLE
	#echo "Done checking quality for $SAMPLE."
	#echo

	#ADAPTER REMOVAL
	echo "Removing adapters for $SAMPLE...."
	cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCACTACGCT -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTACTCTAG -o ./$SAMPLE/"$SAMPLE"_F_trimmed.fastq -p ./$SAMPLE/"$SAMPLE"_R_trimmed.fastq "$SAMPLE"_1.fq.bz2 "$SAMPLE"_2.fq.bz2 -m 30
	echo "Done removing adapters for $SAMPLE."
	echo

	#MERGING
	echo "Merging F and R reads for $SAMPLE...."
	pear -f ./$SAMPLE/"$SAMPLE"_F_trimmed.fastq -r ./$SAMPLE/"$SAMPLE"_R_trimmed.fastq -o ./$SAMPLE/"$SAMPLE" -p 1.0 -v 20 -y 100G -j 4 -q 20 -t 30 -u 0.1
	echo "Done merging F and R reads $SAMPLE...."
	echo

	#rRNA REMOVAL FROM MERGED READS
	echo "Removing rRNA for $SAMPLE...."
	sortmerna --ref /usr/share/bioinf_databases/sortmerna/silva-bac-16s-id90.fasta,/usr/share/bioinf_databases/sortmerna/silva-bac-16s-id90.idx:/usr/share/bioinf_databases/sortmerna/silva-bac-23s-id98.fasta,/usr/share/bioinf_databases/sortmerna/silva-bac-23s-id98.idx:/usr/share/bioinf_databases/sortmerna/silva-arc-16s-id95.fasta,/usr/share/bioinf_databases/sortmerna/silva-arc-16s-id95.idx:/usr/share/bioinf_databases/sortmerna/silva-arc-23s-id98.fasta,/usr/share/bioinf_databases/sortmerna/silva-arc-23s-id98.idx:/usr/share/bioinf_databases/sortmerna/silva-euk-18s-id95.fasta,/usr/share/bioinf_databases/sortmerna/silva-euk-18s-id95.idx:/usr/share/bioinf_databases/sortmerna/silva-euk-28s-id98.fasta,/usr/share/bioinf_databases/sortmerna/silva-euk-28s-id98.idx:/usr/share/bioinf_databases/sortmerna/rfam-5s-database-id98.fasta,/usr/share/bioinf_databases/sortmerna/rfam-5s-database-id98.idx:/usr/share/bioinf_databases/sortmerna/rfam-5.8s-database-id98.fasta,/usr/share/bioinf_databases/sortmerna/rfam-5.8s-database-id98.idx --reads ./$SAMPLE/$SAMPLE.assembled.fastq --fastx --aligned ./$SAMPLE/"$SAMPLE"_rRNA --other ./$SAMPLE/"$SAMPLE"_non_rRNA -a 8 --log -v
	echo "Done removing rRNA for $SAMPLE."
	echo

	#COUNT NUMBER OF READS
	RAWREADS=`bzip2 -dc "$SAMPLE"_1.fq.bz2 | less | wc -l | awk '{print $1/4}'`
	TRIMMEDREADS=`python $PYTHONSCRIPT -i ./$SAMPLE/"$SAMPLE"_F_trimmed.fastq`
	MERGEDREADS=`python $PYTHONSCRIPT -i ./$SAMPLE/"$SAMPLE".assembled.fastq`
	NONRRNAREADS=`python $PYTHONSCRIPT -i ./$SAMPLE/"$SAMPLE"_non_rRNA.fastq`
	echo -e "$SAMPLE""\t""$RAWREADS""\t""$TRIMMEDREADS""\t""$MERGEDREADS""\t""$NONRRNAREADS" >> Number_of_reads.txt

	echo "DONE PROCESSING $SAMPLE."
	echo
	echo

done

date