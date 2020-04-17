#!/usr/bin/perl

# (c) Annelies Haegeman (P39)
# Version 1, 17/04/2020
# Description: this Perl script reads a file containing NCBI taxids (1 per line).
# The script looks up the corresponding species, genus, family, order, class and kingdom using NCBI's efetch.
# Output file: a text file containing the taxonomy in a tab delimited format.
# output format: taxid	kingdom	phylum	class	order	family	genus	species
# Usage: perl get_taxonomy_from_taxids.pl taxids.txt output.txt
# Remark: make sure you first do dos2unix on the input files before you use this script in a Linux environment
# Installation requirements: Perl, Bioperl
#----------------------------------------------------------------------------------

$|=1;
use strict;
use LWP::Simple;	#for efetch
use Data::Dumper;
use Bio::DB::Taxonomy;
use Bio::Tree::Tree;

#use warnings;

die  "usage get_taxonomy_from_taxids.pl taxids.txt output.txt" if (scalar @ARGV != 2);

################
#set parameters#
################
my ($inputfile,$outputfile,$id,$lijn,$taxonid,$db,$taxon,$rank,$name,$tree,@taxa,$first,$species,$speciesname,$genus,$genusname,$family,$familyname,$order,$ordername,$class,$classname,$phylum,$phylumname,$kingdom,$kingdomname,$superkingdom,$superkingdomname);


#############
#input files#
#############
my $inputfile= $ARGV[0];
my $outputfile = $ARGV[1];
open (OP,">$outputfile");
print OP "taxid","\t","superkingdom","\t","kingdom","\t","phylum","\t","class","\t","order","\t","family","\t","genus","\t","species","\n";


###############################################################################
#read input file, find taxid through efetch and access NCBI Taxonomy to retrieve the taxonomy#
###############################################################################
open (IP,$inputfile) || die "cannot open \"$inputfile\":$!";
while ($lijn=<IP>)
	{		
	chomp $lijn;
	$id=$lijn;

	##find taxid by looking up species using NCBI's efetch and then selecting the taxon id
	#$taxonid=""; #first reset in case nothing is found (then taxid stays empty)
	#$taxonid=`esearch -db taxonomy -query "$lijn [LNGE] AND species [RANK]" | efetch -format docsum | xtract -pattern DocumentSummary -element TaxId`;
	#chomp $taxonid;
	##print "$lijn\t$taxonid\n";

	#create a new taxonomy by fetching it from NCBI
	$db = Bio::DB::Taxonomy->new(-source => 'entrez');	#'entrez' source = NCBI Taxonomy
	$taxon = $db->get_taxon(-taxonid => $id);	#gets a Bio::Taxon object from NCBI Taxonomy
	
	#if taxon is found, initialize tree
	if (defined $taxon)
		{
		$name = $taxon->scientific_name;	
		$tree = Bio::Tree::Tree->new(-node => $taxon);	#a bio::tree::tree object can be made of a Bio::Taxon object
		@taxa = $tree->get_nodes;
		
		#get species
   		if (defined $name) 
  			{   	
  			($first, $speciesname) = split(/\s/, $name, 2);	#split only in two parts based on the first space (the first part is genus name, the last part is species name)
  			}
  		else	{
  			$speciesname = "";
  			}  	
  	
  		#get genus
  		$genus = $tree->find_node(-rank => 'genus');		#een Bio::Taxon object
   		if (defined $genus) 
  			{   	
  			$genusname = $genus->scientific_name;
  			}
  		else	{
  			$genusname = "";
  			}  	
  	
  		#get family
  		$family = $tree->find_node(-rank => 'family');	
   		if (defined $family) 
  			{ 
  			$familyname = $family->scientific_name;
  			}
  		else	{
  			$familyname = "";
  			}
  	
  		#get order 	
  		$order = $tree->find_node(-rank => 'order');	
   		if (defined $order) 
  			{ 
  			$ordername = $order->scientific_name;
  			}
  		else	{
  			$ordername = "";
  			}
  	
  		#get class
  		$class = $tree->find_node(-rank => 'class');
  		if (defined $class) 
  			{ 
  			$classname = $class->scientific_name;
  			}
  		else	{
  			$classname = "";
  			}
  	
  		#get phylum
  		$phylum = $tree->find_node(-rank => 'phylum');
  		if (defined $phylum) 
  			{
			$phylumname = $phylum->scientific_name;
  			}
  		else	{
  			$phylumname = "";
  			}	
	
		#get kingdom
		$kingdom = $tree->find_node(-rank => 'kingdom');
		if (defined $kingdom) 
  			{
  			$kingdomname = $kingdom->scientific_name;
  	  		}
  		else	{
  			$kingdomname = "";
  			}	
			
		#get superkingdom
		$superkingdom = $tree->find_node(-rank => 'superkingdom');
		if (defined $superkingdom) 
  			{
  			$superkingdomname = $superkingdom->scientific_name;
  	  		}
  		else	{
  			$superkingdomname = "";
  			}				
  	
		}
	
	#if no taxon was found, put everything to ""
	else	{
		$name="";
		$speciesname="";
		$genusname="";
		$familyname="";
		$ordername="";
		$classname="";
		$phylumname="";
		$kingdomname="";
		$superkingdomname="";
		}
	
	print OP "$id","\t","$superkingdomname","\t","$kingdomname","\t","$phylumname","\t","$classname","\t","$ordername","\t","$familyname","\t","$genusname","\t","$speciesname","\n";
	
	}	

