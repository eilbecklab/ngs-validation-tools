use Getopt::Std;
use File::Path;
use strict;
use File::Basename qw(basename);

# NOTES:
# BwaSamGatFreSnp1.0.pl
# This script is a generic BWA/Samtools/GATK/FreeBayes/snpEFF/SNPsift alignment script.
# This script can be used with any paired fastq files as long as the fasts, bed file(s), and output file name are entered into the CMD line.

###	PROGRAMS REQUIRED (located in genseqar01:/mnt/research1/tools/):
#	bwa 0.6.1-rep104
#	samtools 0.1.18 (r982:295)
#	bcftools 0.1.17-dev (r973:277)
#	vcftools 0.1.17-dev (r973:277)
#	GenomeAnalysisTK-3.1.1
#  FreeBayes v0.9.14-6-g41b5ada
#  SNPeff v4_0c

# FILES
# genseqar01:/mnt/research1/reference/human_g1k_v37.fasta


START:	
print "\nSingle Gene or Panel\n"; # VERSION INFORMATION
print "\nSHALE DAMES\n"; # DATE VALIDATED
print "\nREPORTS VARIANTS FOR DROSHA NM_013235.4\n\n";

###  CMD LINE INPUT FASTQ1
# -b input bam
use vars qw/$opt_b/; # calls option -b
getopt('b');
my $read1=shift; # bam
	chomp $read1;
	unless (open (read1, $read1) ) 
			{
    				print 
"\nUSAGE: perl WhitneyDrosha.pl –b <input bam file> -qc <qc.bed file> -out <output file name>.  This script should be run from the directory containing the fastq files.

-b	Input bam file
-qc	Quality control bed file
-out	Output file name

Shale Dames | WhitneyDrosha.pl | Thu Jul 28 03:57:29 MDT 2016 \n\n";
   					exit;
			}			

###  CMD LINE INPUT QUALITY CONTROL QC BED FILE
# -qc quality control bed file
use vars qw/$opt_qc/; # calls option -qc
getopt('qc');
my $qcbed=shift; # qc bed
	chomp $qcbed;
	unless (open (qcbed, $qcbed) ) 
			{
    				print 
"\nUSAGE: perl WhitneyDrosha.pl –b <input bam file> -qc <qc.bed file> -out <output file name>.  This script should be run from the directory containing the fastq files.

-b	Input bam file
-qc	Quality control bed file
-out	Output file name

Shale Dames | WhitneyDrosha.pl | Thu Jul 28 03:57:29 MDT 2016 \n\n";
   					exit;
			}		
			
###  CMD LINE OUTPUT FILE		
# -out output file
use vars qw/$opt_out/; # calls option -out
	getopt('out');
	my $file = shift; # output file
	chomp $file;
			
### PRINT INPUT AND START
print "Analysis started on: ";
system ("date \n");
print "Input bam \"$read1\"\n";
print "QC bed file is \"$qcbed\"\n";
print "Output file name \"$file\"\n\n";

### PROGRAMS FILES
# Edit directories and programs to make the script transferable to other servers if not on genseqar01
my $file = $file;
my $jar = "java -Xmx16g -jar ";																																		#<----------- java -jar settings
	my $Free = "/mnt/research1/tools/freebayes";																											#<----------- FreeBayes directory			
	my $vcftools= "/mnt/research1/tools/vcftools_0.1.11/perl/vcf-sort ";																			#<----------- vcftools directory
	my $snpSift = "/mnt/research1/tools/snpEff_4_0/SnpSift.jar ";																					#<----------- SnpSift directory
	my $snpEff = "/mnt/research1/tools/snpEff_4_0/snpEff.jar ";																						#<----------- snpEff directory
my $vcftools2 = "/mnt/research1/tools/vcftools_0.1.11/bin/vcftools";																				#<----------- vcftools2 directory

### REFERENCE FILES
# Edit directories and reference files to make the script transferable to other servers if not on genseqar01
my $RefSeq = "/mnt/research1/reference/human_g1k_v37.fasta";																				#<----------- RefSeq directory
	my $dbSNP = "/mnt/research1/reference/All.dbsnp.142.sd.vcf ";																				#<----------- dbSNP directory
	my $HGMDsnp = "/mnt/research1/reference/HGMD_SNP_May_2014_1.sorted.vcf";												#<----------- HGMDsnp sorted directory
my $HGMDind = "/mnt/research1/reference/HGMD_Indel2014_Results_sort.vcf";														#<----------- HGMDind sorted directory

### PRINT DIRECTORIES AND SOFTWARE USED
print "\nFiles used:\n";
	print "$RefSeq\n";
	print "$dbSNP\n";
	print "$HGMDsnp\n";
print "$HGMDind\n";

### CREATE NM.TXT FILE FROM BED FILE
system ("cut -f4 $qcbed | sed 's/_cds.*//' > input.txt"); # extracts column 4 from tmp.txt and removes all but NM_<number>
	system ("uniq input.txt > UniqueTranscripts "); # removes duplicate NMs	
## The following is a lame and inelegant way to get around versioning issues with snpEff transcript files ##
	system ("awk '{for (i=0; i<20; i++) print}' UniqueTranscripts > temp.txt"); # creates 20 copies of each unique transcript
	system ("seq 1 20 > count.txt"); # creates a file "count.txt" with numbers 1 - 20 in sequential order with each number on a new time
	system ("sed 's/^/./' count.txt > count2.txt"); # inserts "." at the beginning of each line
	system ("wc -l < UniqueTranscripts > num.txt"); # prints out only number of lines in file "UniqueTranscripts" creates "num.txt"
	system ("seq \$(<num.txt)\ | xargs -I INDEX cat count2.txt > count.txt"); # sequentially repeats 1 -20 for "n" unique transcripts and creates count.txt
	system ("paste temp.txt count.txt | sed 's/\t//g' > NM.txt"); # concatenates transcripts and removes tabs, creates NM.txt
## End multi version transcript file creation --> NM.txt ##
	print "\nCreate NM.txt file\n"; # printed text
	print "\nLine count NM.txt (\"$qcbed\") and Unique Transcripts\n"; # printed text
	system ("wc -l \$qcbed\ UniqueTranscripts NM.txt | sed -n 1,2p\n"); # provides line count information of pre and post duplicate line removal
#system ("rm input.txt count* num.txt temp.txt"); # removes unwanted files
### COMPLETE NM.TXT FILE FROM BED FILE

### PRINT FREEBAYES INFORMATION ###
print "\nFreeBayes version information:\n";
system ("/mnt/research1/tools/freebayes -h | tail -2"); # prints FreeBayes help screen tailed for version
### END PRINT FREEBAYES INFORMATION ###

### BEGIN FREEBAYES VCF GENERATION
print "\nFeeBayes vcf generation\n"; # printed text
print "  CMD: $Free -f $RefSeq -U 4 -m 30 -q 20 -D 0.2 -t $qcbed $file.SAM.final.bam > $file.FreeBayes.vcf \n\n"; # prints CMD

### PRINT SNPEFF INFORMATION ###
system ("$jar /mnt/research1/tools/snpEff_4_0/snpEff.jar -h"); # prints SNPeff help screen
### END PRINT SNPEFF INFORMATION ###

### BEGIN VCF-SORT 
print "\nvcf-sort freebayes vcf file for snpEff processing\n"; # printed text
	print "CMD: perl $vcftools -c $file.FreeBayes.vcf > $file.tmpSort.vcf\n\n"; # prints CMD
system ("perl $vcftools-c $file.FreeBayes.vcf > $file.tmpSort.vcf\n\n"); # Freebayes vcf generation and post generation vcf sort
# Process description: Creates annotated .vcf file $file.AllGenesSNAP.vcf from freebayes vcf $file.Free.vcf
	# perl invokes perl (required)
	# vcf-sort (sorts freebayes generated vcf file)
	# $vcftools • clinical vcf-sort location
	# -c • OPTION: sort by chromosomal position
	# $file.FreeBayes.vcf • freebayes generated vcf file (input file)
	# $file.tmpSort.vcf • sorted $file.Freebayes.vcf (output file)
### END VCF-SORT 

### BEGIN SNPSIFT ANNOTATION dbSNP ###
system ("$jar $snpSift annotate $dbSNP $file.tmpSort.vcf> $file.raw.vcf\n");
print "\nRaw vcf SnpSift \"$dbSNP\" dbSNP annotation ($file)\n";
print "  CMD: $jar $snpSift annotate $dbSNP $file.tmpSort.vcf > $file.raw.vcf\n\n";
# snpSift \"$dbSNP\" vcf annotation ($file)\n • printed text; $file.raw.vcf will contain information for all tags in the Info column
# Process description: Creates dbsnp annotated .vcf file $file.snpSift.vcf from $file.tmpSort.vcf									#--------->this file contains all info tag fields		
	# $jar: • java memory settings (see line 126)	
	# $snpSift • location of clinical snpSift directory
	# $dbSNP • location of dbSNP 
	# $file.tmpSort.vcf • input vcf
	# $file.raw.vcf • output vcf
### END SNPSIFT ANNOTATION dbSNP ### 

### BEGIN SNPSIFT ANNOTATION HGMDsnp ###
system ("$jar $snpSift annotate $HGMDsnp $file.raw.vcf> $file.raw2.vcf\n");
	print "\nRaw vcf SnpSift \"$HGMDsnp\" HGMD SNP annotation ($file)";
print "\n  CMD: $jar $snpSift annotate $HGMDsnp $file.raw.vcf> $file.raw2.vcf\n";
# snpSift \"$dbSNP\" vcf annotation ($file)\n • printed text; $file.raw.vcf will contain information for all tags in the Info column
# Process description: Creates dbsnp annotated .vcf file $file.snpSift.vcf from $file.tmpSort.vcf									#--------->this file contains all info tag fields			
	# $jar: • java memory settings (see line 126)
	# $snpSift • location of clinical snpSift directory
	# $dbSNP • location of dbSNP											
	# $file.tmpSort.vcf • input vcf
	# $file.raw.vcf • output vcf
### END SNPSIFT ANNOTATION HGMDsnp ### 

### BEGIN SNPSIFT ANNOTATION HGMDindedl ###
system ("$jar $snpSift annotate $HGMDind $file.raw2.vcf> $file.raw3.vcf\n");
print "\nRaw vcf SnpSift \"$HGMDind\" HGMD indel annotation ($file)";
print "\n  CMD: $jar $snpSift annotate $HGMDind $file.raw2.vcf> $file.raw3.vcf\n";
# snpSift \"$dbSNP\" vcf annotation ($file)\n • printed text; $file.raw.vcf will contain information for all tags in the Info column
# Process description: Creates dbsnp annotated .vcf file $file.snpSift.vcf from $file.tmpSort.vcf									#--------->this file contains all info tag fields			
	# $jar: • java memory settings (see line 126)
	# $snpSift • location of clinical snpSift directory
	# $dbSNP • location of dbSNP														
	# $file.tmpSort.vcf • input vcf
	# $file.raw.vcf • output vcf
### END SNPSIFT ANNOTATION HGMDindedl ### 

###CREATE FINAL VCF###
print "\nsnpEff vcf annotation ($file)"; # printed text
	system ("$jar $snpEff -v -hgvs -ss 10 -s $file.summary.html -no downstream -no upstream -no intergenic -no intron hg19 -onlyTr NM.txt $file.raw3.vcf > $file.FINAL.vcf");
	print "\n  CMD $jar $snpEff  -v -hgvs -ss 10 -s $file.summary.html -no downstream -no upstream -no intergenic -no intron hg19 -onlyTr NM.txt $file.raw3.vcf> $file.FINAL.vcf\n";
print "\nAdd HGMD information ($file)\n"; # printed text
###END FINAL VCF###

# EXTRACT HGMD EFFECTS 
system ("sed 's/disease/\tdisease/g' $file.raw3.vcf | sed 's/;gene/\t\t;gene/g' > dis.txt"); # start extraction of disease info by tabbing out information
system ("cut -f1,9 dis.txt | sed 's/GT.*/\t/g' | sed '/##/d' | sed '1d' | cut -f2 | sed 's/disease=//g' | sed -e 's/\t//g' | sed -e 's/^\$/\t/g' > disease.txt");
system ("paste gene.txt disease.txt zyg.txt aaChange.txt gdot.txt cdot.txt pdot.txt ref.txt alt.txt freq.txt rs.txt exon.txt risk.txt depth.txt qual.txt ratio.txt nm.txt | sed 's/\t\t/\t/g' > $file.tab"); # create temp tab report, remove any tab format issues

# ANNOTATE FILES
system ("$qcbed ."); # copies qcbed for manipulations
system ("cut -f1-2 $qcbed | sed 's/\t/:/g' > t1"); # format first columns for grep
system ("cut -f2 $qcbed > t2"); # format first columns for grep
system ("paste t1 t2 | sed 's/\t/-/g' > t3 "); # pastes "IGV" format
system ("cut -f4 $qcbed | sed 's/_/\t/g' > t4"); # tabs out "_" in bed info line
system ("cut -f1,2 t4 | sed 's/\t/_/g' > t1"); # cuts the first 2 columns and replaces tabs with _ for transcripts
system ("cut -f3,4 t4 | sed 's/cds\t/exon_/g' | sed 's/\t/_/g' > t2"); # manipulates columns 3 and 4 to extract exon number
system ("paste t1 t2 | sed 's/\t/_/g' > t4"); # pastes transcripts and exons together
system ("paste t3 t4 > CovDep.txt | rm t1 t2 t3 t4"); # pastes IGV chromosome format and transcripts/exons together, removes intermediate files and creates CovDep for greping



