## Metatranscriptomics_marine_sediment

### Introduction and purpose of the study
The scripts in this repository are accompanying the paper **"Nematodes facilitate bacterial-mediated biogeochemical processes in marine sediments: a meta-transcriptomics approach"** by Rodgee Mae Guden, Annelies Haegeman, Tom Ruttink, Tom Moens and Sofie Derycke (Ghent University / ILVO, Belgium). This study used meta-transcriptomics to investigate taxonomic and functional shifts in marine sediment bacterial communities in response to the addition of a nematode community. Be aware that all scripts and commands were used on servers from ILVO and Ghent University, and might not work on other servers depending on how/where the software and/or databases were installed.

### Preprocessing
The following steps are done in the preprocessing:
* Quality check using [`FastQC`](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
* Removal of adapter sequences. Since fragment lengths are often smaller than 150 bp (the sequencing length), you can read Illumina's universal adapter sequence at the 3' end of the reads (both forward and reverse reads). We therefore trim these universal adapters using [`cutadapt`](https://cutadapt.readthedocs.io/en/stable/) (Martin,2011). We also decide to only keep trimmed sequences longer than 30 bp.
* Merging of forward and reverse reads. Since fragment lengths are often smaller than 300 bp, and since we sequence 2x150 bp, it is possible that the forward and reverse reads overlap. Using the software [`PEAR`](http://www.exelixis-lab.org/web/software/pear) (Zhang et al., 2014) we can make the overlap of the forward and reverse reads ("assembled" reads), with a minimum overlap length of 20 bp.
* [`SortmeRNA`](https://bioinfo.lifl.fr/RNA/sortmerna/) (Kopylova et al., 2012) to check which fraction of the reads are rRNA. All merged ("assembled") reads are checked against all rRNA databases provided with the `SortmeRNA` software. Reads are hence classified in two groups: rRNA reads and non rRNA reads.
* Finally, a table is made which summarizes the number of reads left after each processing step.

The preprocessing script should be opened using `Notepad++` or a similar text editor, and the following things should be changed:
`DIR` and `PYTHONSCRIPT` containing the directory of the raw data on the one hand and the python script `FastQ_CountReads.py` on the other hand (script is also in this repository).

For example:
```
DIR=/home/genomics/ALL_RAW_SEQ_DATA/10_Marine_microbial/Metatranscriptomics/18094-05
PYTHONSCRIPT="/home/genomics/ahaegeman/GitLab/Metatranscriptomics_marine_sediment/FastQ_CountReads.py"
```

Make sure you save the script. Next, you can run it as follows:

`bash RNAseq_preprocessing.sh`

The script will do all analysis steps described above, and will save the results in the folder where the raw data is (`DIR` in the script). It will do this for all samples in the folder, and the results will be saved in subfolders with the sample name as name.
It will also make a text file with the number of reads kept after each step for each sample.


### Taxonomic composition of the reads

The resulting preprocessed reads can be checked for their taxonomic composition using [`Kraken2`](https://ccb.jhu.edu/software/kraken2/) (Wood et al., 2020). `Kraken2` is metagenomics software which classifies each individual read up to a certain taxonomic level, as specific as possible. In our case, we compare with a custom-built `Kraken2` database which was made from the complete Genbank nucleotide database (July 2019).

`kraken2 <options> inputfile`

`kraken2 --db <path to database> --memory-mapping --threads <int> --output <output file> --report <report file> inputfile`

With options:

`--db` : path to local kraken2 databases

`--memory-mapping` : do not load database in RAM to keep the memory usage as low as possible

`--threads` : number of processors used

`--output` : file name for kraken2 output file

`--report` : file name for kraken2 report file

Example:

`kraken2 --db /usr/share/bioinf_databases/kraken2/NCBI_nt --memory-mapping --threads 32 --output 022_010_191206_999_0007_004_01_2141.assembled.kraken2.output.txt --report 022_010_191206_999_0007_004_01_2141.assembled.kraken2.report.txt 022_010_191206_999_0007_004_01_2141.assembled.fastq`

Finally, the `Kraken2` results can be visualized using [`Krona`](https://github.com/marbl/Krona/wiki) (Ondov et al., 2011). We use the `ImportTaxonomy` script from `Krona` to produce the plots. This script can directly use the output of `Kraken2` as inputfile.

`ImportTaxonomy.pl <options> inputfile`

`ImportTaxonomy.pl -tax <path to Krona taxonomy> -q <int> -t <int> -o <output file> inputfile`

With options:

`-tax` : path to local taxonomy database for Krona

`-q` : Column of input files to use as query ID

`-t` : Column of input files to use as taxonomy ID

`-o` : file name for Krona output file


Example:

`ImportTaxonomy.pl -tax /usr/share/bioinf_databases/Krona/taxonomy -q 2 -t 3 -o 022_010_191206_999_0007_004_01_2141.assembled.kraken.html 022_010_191206_999_0007_004_01_2141.assembled.kraken2.output.txt`

### Make a big count table of all observed taxids containing all samples

#### Look up the taxonomy from the Kraken2 output

The `Kraken2` output files are actually a classification of each read with the NCBI taxid it was assigned to. If we want to make comparisons between the taxonomic composition of the different samples, we need to put all samples together in 1 "taxonomy count" table, with taxid as unique identifier of the taxa. This of course has some redundant information. Some sequences are classified up to a higher taxonomic level than others. For example, 1 sequence can be classified up to species level, and another sequence can be classified up to order level only, while both sequences might have originated from the same organism. Therefore it makes sense to make a database with all observed taxids, with their fully linked taxonomy.

First, we create a list of all observed taxids by combining the `Kraken2` output files, extracting the third column of all these files (with the taxid), and removing double taxids. This can be done using simple Linux commands:

`cat sample1.assembled.kraken2.output.txt sample2.assembled.kraken2.output.txt sample3.assembled.kraken2.output.txt | cut -f3 | sort -n | uniq > taxids.txt`

Next, we can use NCBI's `efetch` tools to look up the corresponding taxonomy to each of the taxids by making connection to the NCBI servers. We built a perl wrapper script to do this and to nicely format the output. The perl script takes as first argument a list of taxids (1 per line), and as second argument a name for the output file.

`perl get_taxonomy_from_taxids.pl taxids.txt output.txt`

**Important note:** The script will probably fail multiple times with long lists of taxids. This is due to a lost connection to the NCBI servers. When this happens, the only solution is to check up until which taxid the output was created, and then restart the script using the next taxids as input. In the end you can recombine all created output files using the `cat` command.

The resulting file contains in each row the taxid with the corresponding taxonomy of every observed taxon in at least one of the samples. This file "taxonomy.txt" will be used in the R script (see section "Merge all count tables").

#### Make a simple count table per sample

Next, we make a simple count table per sample. We use the `kraken2` output file, which lists for each read to which taxid it was assigned. By using the Linux `sort | uniq -c` commands, we can easily count how many observations were done for each taxid. For example:

`cut -f3 191206_07.assembled.kraken2.output.txt | sort | uniq -c > 191206_07_rawcounts.txt`

In these count tables, we replace the leading spaces by nothing:

`sed -i 's/^ *//g' 191206_07_rawcounts.txt`

And finally, we replace the remaining space between the values by a tab to have a tab delimited file:

`sed -i -e 's/ /\t/g' 191206_07_rawcounts.txt`

We make these simple count tables for all samples. In the next section, we will merge all these count tables.

#### Merge all count tables

All individual count tables can be merged to a single count table, where all read counts are listed per sample for each observed taxid. The merging of the individual tables is done using the R script `Process_kraken2_taxcounts.R`. The script reads the following files
- "taxonomy.txt" : a file containing the full taxonomy of each observed taxid (see section "Lookup the taxonomy")
- "metadata.txt" : a file with some information on the samples
- multiple "rawcounts.txt" files, 1 for each sample : raw count files with the counts of each observed taxid (1 file corresponds to 1 sample).

In the script, the following is done:
- individual count files are merged into 1 big count table (setting unobserved taxa to 0)
- count table is merged with the taxonomy and metadata to a phyloseq object (see package [phyloseq](https://joey711.github.io/phyloseq/))
- some basic operations on phyloseq objects: filtering low abundant counts, extracting counts from "Bacteria" only, summing all counts belonging to the same taxon ("tax_glom" function), making barplots.

### COG analysis

The bash script `cog_analysis.sh` can be used to perform functional analyses for RNA-seq data from metatranscriptomics datasets by assigning COG (Cluster of Orthologous Genes) to non-rRNA reads (output of SortMeRNA).

The steps in this script are:

1.   Converting fastq to fasta
2.   Translating the read sequences to amino acids using [`FragGeneScan`](https://omics.informatics.indiana.edu/FragGeneScan/) (Rho et al., 2010)
3.   Blasting the query proteins with RPS-BLAST+ against NCBI's [Conserved Domain Database (CDD)](https://www.ncbi.nlm.nih.gov/cdd/)
4.   Assigning COG (cluster of orthologous groups) categories to proteins.
5.   Combining the cog outputs of all samples into one count table.

### Pathway analysis

The bash script `pathway_analysis.sh` can be used to perform functional analyses for RNA-seq data from metatranscriptomics datasets by assigning enzymes and metabolic pathways to non-rRNA reads using the [KEGG database](https://www.genome.jp/kegg/pathway.html).

Prior step: de novo assembly of reads using the CLC Genomics Workbench de novo assembler.

The steps in the pathway analysis script are:

1.  Annotating the non-rRNA reads using [`Prokka`](https://github.com/tseemann/prokka) (Seemann, 2014).This program searches for open reading frames (ORFs) on contigs, translates ORFs to protein sequences, and assigns enzyme identifiers to the coding regions.
2.  Extracting lists of Prokka genes that can be assigned with enzyme identifiers.
3.  Converting the gff output of Prokka to a gtf file.
4.  Mapping the original non-rRNA reads onto the assembly using [`Bowtie2`](https://github.com/BenLangmead/bowtie2) (Langmead & Salzberg, 2012), and sorting and indexing the resulting alignment files with [`SAMtools`](https://github.com/samtools/samtools) (Danecek et al., 2021).
5.  Predicting metabolic pathways using [`Minpath`](https://github.com/mgtools/MinPath) (Ye & Doak, 2009).
6.  Converting bam files to a count table. This uses the `bam_to_count_table.R` R script.
7.  Assigning enzyme identifiers to annotated prokka genes using the KEGG database.
8.  Assigning pathway names to enzyme identifiers using the KEGG database.

### License

This work is distributed under a [CC BY 4.0 license](https://creativecommons.org/licenses/by/4.0/).

### References


Danecek, P., Bonfield, J.K., Liddle, J., Marshall, J., Ohan, V., Pollard, M.O., Whitwham, A., Keane, T., McCarthy, S.A., Davies, R.M., Li, H. Twelve years of SAMtools and BCFtools. GigaScience, 10 (2), giab008.

Kopylova, E., Noé, L., Touzet, H., 2012. SortMeRNA: fast and accurate filtering of ribosomal RNAs in metatranscriptomic data, Bioinformatics 28, 3211–3321.

Langmead, B, Salzberg, S. 2012. Fast gapped-read alignment with Bowtie 2. Nature Methods, 9, 357-359.

Martin, M., 2011. Cutadapt removes adapter sequences from high-throughput sequencing reads. EMBnet.journal 17, 10.

Ondov, B.D., Bergman, N.H. & Phillippy, A.M., 2011. Interactive metagenomic visualization in a Web browser. BMC Bioinformatics 12, 385.

Rho, M., Tang, H. & Ye, Y. 2010. FragGeneScan: Predicting Genes in Short and Error-prone Reads. Nucleic Acids Research, 38 (20), e191.

Seemann, T. 2014. Prokka: rapid prokaryotic genome annotation. Bioinformatics, 30 (14), 2068-2069.

Wood, D.E., Lu, J. & Langmead, B. 2019. Improved metagenomic analysis with Kraken 2. Genome Biology 20, 257.

Ye, Y., Doak, T.G. A parsimony approach to biological pathway reconstruction/inference for genomes and metagenomes. 2009. PLoS Computational Biology, 5(8), e1000465.

Zhang, J., Kobert, K., Flouri, T., Stamatakis, A., 2014. PEAR: A fast and accurate Illumina Paired-End reAd mergeR. Bioinformatics 30, 614–620.
