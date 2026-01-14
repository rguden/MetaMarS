#!/usr/bin/env Rscript

#Author: Rodgee Mae Guden
#Previous analyses: de novo assembly - prokka - gff_to_gtf - bowtie - samtools
#This script uses the gtf annotation file and BAM files created in the previous steps.
#This creates a count table of the number of reads for each annotated Prokka genes for all samples.

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("Rsubread")

setwd("/media/HD3/home/rguden/Desktop/Documents/RNA/Final scripts/data/step_4_pathway")

#LOAD PACKAGES
library(Rsubread) #for featureCounts

#READ files
#specify path to GTF annotation file
gtffile="/media/HD3/home/rguden/Desktop/Documents/RNA/Final scripts/data/step_3_pathway/output/PROKKA_07092021.gtf"

#specify list of BAM files, this should be a vector with a list of your bam files, including their path if not in R's working directory
bamfls<-c("All_non-rRNA_R2_612_0007.bam", "All_non-rRNA_R2_1312_0005.bam", "All_non-rRNA_R3_612_0017.bam", "All_non-rRNA_R3_1312_0009.bam", "All_non-rRNA_R4_612_0019.bam", "All_non-rRNA_R4_1312_0011.bam",
          "All_non-rRNA_R5_612_0015.bam", "All_non-rRNA_R5_1312_0016.bam", "All_non-rRNA_R6_612_0018.bam", "All_non-rRNA_R6_1312_0020.bam", "All_non-rRNA_WR2_612_0008.bam", "All_non-rRNA_WR2_1312_0006.bam",
          "All_non-rRNA_WR3_612_0021.bam", "All_non-rRNA_WR3_1312_0010.bam", "All_non-rRNA_WR4_612_0013.bam", "All_non-rRNA_WR4_1312_0012.bam", "All_non-rRNA_WR5_612_0022.bam", "All_non-rRNA_WR5_1312_0014.bam",
          "All_non-rRNA_WR6_612_0023.bam", "All_non-rRNA_WR6_1312_0024.bam")

#MAKE COUNT TABLE FROM BAM FILES + ANNOTATION FILE
#make a count table from the bam files based on annotation file, note that we use "featureType CDS" here, this is also what you want since there is CDS in one of your annotation columns.
fcCI=featureCounts(files=bamfls,annot.ext=gtffile,isGTFAnnotationFile=TRUE,GTF.featureType="CDS",isPairedEnd=FALSE,nthreads=4)

#save count table to disk for later use
#saveRDS(fcCI, paste0(dir,"/","fcCI.rds"))
#fcCI <- readRDS(paste0(dir,"/","fcCI.rds")) #to reload the count table from disk later
#check out created object
str(fcCI)
#extract counts from the object
countTableCI=fcCI$counts
colnames(countTableCI)
#write raw count table to output
write.table(countTableCI,file="counttable_CLC.txt",sep="\t",row.names=TRUE,col.names=NA,quote=FALSE)#the col.names=NA writes the column names with an extra empty tab before them
#check out total readcounts for each sample
colSums(countTableCI)
max(colSums(countTableCI))
min(colSums(countTableCI))

#convert counttable_CLC.txt to a tsv file and rename as CountTable_CLC_Gene.tsv.

#The output can be found in "/media/HD3/home/rguden/Desktop/Documents/RNA/Final scripts/data/step_6_pathway/CountTable_CLC_Gene.tsv".
