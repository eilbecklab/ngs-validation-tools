use Getopt::Std;
use File::Path;
use strict;
use File::Basename qw(basename);

# NOTES:
# Fatstq2Bam.pl
# This script is mimics the original "pipeline" alignment from fastqs through RAW bam files

###	PROGRAMS REQUIRED (located in genseqar01:/mnt/research1/tools/):
#	bwa 0.6.1-rep104
#	samtools 0.1.18 (r982:295)

START:	
print "\nPAIRED-END BAM FILE GENERATION FOR CNV\n"; # VERSION INFORMATION
print "THIS SCRIPT PROCESSES FASTQS USING BWA AND SAMTOOLS TO CREATE RAW BAM AND BAM.BAI FILES\n";
print "\nSHALE DAMES NOVEMBER\n"; # DATE VALIDATED

###  CMD LINE INPUT FASTQ1
# -f1 fastq read1
use vars qw/$opt_f1/; # calls option -f1
getopt('f1');
my $read1=shift; # fastq read
	chomp $read1;
	unless (open (read1, $read1) ) 
			{
    				print 
"\nUSAGE: perl TraceyFastq.pl –f1<fastq read1> -f2 <fastq read 2> -out <output file name>.  This script should be run from the directory containing the fastq files.

-f1	fastq read 1
-f2	fastq read 2
-out	Output file name

Shale Dames | TraceyFastq.pl | Tue Nov 24 11:12:14 MST 2015\n\n";
   					exit;
			}			

###  CMD LINE INPUT FASTQ2
# -f2 fastq read2
use vars qw/$opt_f2/; # calls option -f2
getopt('f2');
my $read2=shift; # fastq read
	chomp $read2;
	unless (open (read2, $read2) ) 
			{
    				print 
"\nUSAGE: perl TraceyFastq.pl –f1<fastq read1> -f2 <fastq read 2> -out <output file name>.  This script should be run from the directory containing the fastq files.

-f1	fastq read 1
-f2	fastq read 2
-out	Output file name

Shale Dames | TraceyFastq.pl | Tue Nov 24 11:12:14 MST 2015\n\n";
   					exit;
			}
			
###  CMD LINE OUTPUT FILE		
# -out output file
use vars qw/$opt_out/; # calls option -out
	getopt('out');
	my $file = shift; # output file
	chomp $file;
			
### PRINT INPUT AND START
print "\nAnalysis started on: ";
system ("date \n");
print "fastq read 1 \"$read1\"\n";
print "fastq read 2 \"$read2\"\n";
print "Output file name \"$file\"\n\n";

### PROGRAMS FILES
# Edit directories and programs to make the script transferable to other servers if not on genseqar01
my $file = $file;
	my $BWA = "/mnt/research1/tools/bwa-0.6.1/bwa";																									#<----------- BWA directory
	my $SAM = "/mnt/research1/tools/samtools-0.1.18/samtools";																					#<----------- samtools directory
	
### REFERENCE FILES
# Edit directories and reference files to make the script transferable to other servers if not on genseqar01
my $RefSeq = "/mnt/research1/reference/human_g1k_v37.fasta";

### PRINT DIRECTORIES AND SOFTWARE USED
print "Software used:\n";
	print "$BWA\n";
	print "$SAM\n";
	
### PRINT DIRECTORIES AND SOFTWARE USED
print "\nFiles used:\n";
	print "$RefSeq\n";

### DISPLAY START TIME AND LIST FILE DIRECTORY
print "\nBam file generation starrted at:\n";
	system ("date\n"); # start time
	system ("ll"); # file directory--lists files in current directory
					
### BWA .SAI GENERATION
print "\nBWA .sai generation\n"; # printed text	
		my $bwa1 = "$BWA aln -t12 $RefSeq $read1 > $read1.sai";# aligns 1st read with 12 threads to reference sequence
		my $bwa2 = "$BWA aln -t12 $RefSeq $read2 > $read2.sai";# aligns 2nd read with 12 threads to reference sequence
		chomp $bwa1;
		chomp $bwa2;
		my $bwa_aln1 = system ("$bwa1"); # bwa alignment 1 (.sai)
		wait;	
my $bwa_aln2 = system ("$bwa2"); # bwa alignment 2 (.sai)
# Process description: Aligns $read1 and $read2 to create .sai files using BWA aln
	# $BAM: • clinical BWA location (see line 126)
	# aln • CMD used for .sai generation
	# -t12 • OPTION: number of threads
	# $RefSeq • location and version of clinical reference genome
	# $read1 • fastq read 1 input file
	# $read2 • fastq read 2 input file
	# $read1.sai • output read 1 .sai file
	# $read2.sai • output read 2 .sai file
### END BWA .SAI GENERATION						

### BWA SAMPE
print "\nBWA sampe\n"; # printed text
	my $RG = "\@RG\\tID:\$file.ID\\tLB:\ $file\\tPL:\ILLUMINA\\tPU:\UNKNOWN\\tSM:\Sample"; #RG header line required
	system ("$BWA sampe -t10 -r \"$RG\"  $RefSeq $read1.sai $read2.sai $read1 $read2 > $file.sam"); 
print "  CMD: $BWA sampe -t10 -r \"$RG\"  $RefSeq $read1.sai $read2.sai $read1 $read2 > $file.sam\n";
# Process description: Creates paired end alignment fro read 1 and read 2 sai files using BWA sampe
	# $BAM: • clinical BWA location (see line 126)
	# sampe • CMD used for sampe (generates paired end alignment)
	# -t10 • OPTION: number of threads
	# -r • Read group assignment required for downstream .vcf generation
	# my $RG = \@RG\\tID:\$file.ID\\tLB:\$file\\tPL:\ILLUMINA\\tPU:\SPRI-TE\\tSM:\$read1 • assigns ID ($file.ID), LaBel ($file), PLlatform (Illumina), PU (SPRI-TE), and SM ($read1)
	# $RefSeq • location and version of clinical reference genome
	# $read1.sai • output read 1 .sai file
	# $read2.sai • output read 2 .sai file
	# $read1 • fastq read 1 input file
	# $read2 • fastq read 2 input file
### END BWA .SAI GENERATION						

### CLEAN UP FILES 1
system ("rm $read1.sai $read2.sai"); # Removes .sai files generated during BWA align to save storage space.
print "\n --> Clean up files 1: rm $read1.sai $read2.sai\n";

### SAMTOOLS VIEW
print "\nSamtools view\n"; # printed text
	system ("$SAM view -bS $file.sam > $file.bam");
print "  CMD: $SAM view -bS $file.sam > $file.bam\n";
# Process description: Creates bam file from sam file generated during BWA ampe using samtools view
	# $SAM: • clinical samtools location (see line 126)
	# view • CMD used for converting sam file to bam file
	# -b • OPTION: output is bam file
	# -S • OPTION: input is sam file
	# $file.sam • sam input file
	# $file.bam • bam output file
### END SAMTOOLS BAM GENERATION				

### SAMTOOLS 1ST SORT
print "\nFirst Samtools sort\n"; # printed text
	system ("$SAM sort $file.bam $file.raw"); 
print "  CMD: $SAM sort $file.bam $file.raw\n";
# Process description: Creates the sorted bam file based on chromosomal coordinates from the unsorted bam file
	# $SAM: • clinical samtools location (see line 126)
	# sort • CMD used for sorting bam file
	# $file.bam • bam input file
	# $file.first_sort • sorted bam output file (.bam is automatically added to $file.first_sort)
### END SAMTOOLS 1ST SORT								 
	
### SAMTOOLS INDEX
print "\nFirst Samtools index\n"; # printed text
	my $sam_index = system ("$SAM index $file.raw.bam"); 
print "  CMD: $SAM index $file.raw.bam\n";
# Process description: Creates a sorted, indexed bam from $file.first_sort.bam
	# $SAM: • clinical samtools location (see line 126)
	# index • CMD used for sorting bam file
	# $file.first_sort.bam • bam input file (automatically creates $file.first_sort.bam.bai)
### END SAMTOOLS INDEX					

### CLEAN UP FILES 2 AND CREATE DIRECTORY
print "\n --> Clean up files 2: rm $file.sam $file.bam, move files to directory $file\n";
system ("rm $file.sam $file.bam"); # removes original sam and bam prior to sorting
system ("mkdir $file"); # makes directory named after user defined ourput
system ("mv $file.raw.bam $file.raw.bam.bai $read1 $read2 $file"); # moves fastqs and all files into directory "$file"

### DISPLAY END TIME
print "\nBam file generation finished at:\n";
system ("date"); # end time
print "\nCongratulations Dr. Lewis, your bam file gereation is complete.  Have a splendid day!  And don't drive like my brother....\n";

### VALIDATED SHALE DAMES Tue Nov 24 11:53:38 MST 2015
