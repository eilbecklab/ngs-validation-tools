use Getopt::Std;
use File::Path;
use strict;
use File::Basename qw(basename);

# Notes: Line 64 had to be modified to work appropriately on genseqar01.  Hashed out line 65 works locally on Macs.

# AUTHOR: Shale Dames
# VALIDATED: Shale Dames Wed Jan  7 18:44:02 MST 2015
# genseqar01 VALIDATION: Shale Dames Thu Jan  8 13:16:33 MST 2015

#  ABOUT
#  BedConverterSD.pl converts UCSC generated bed files to the proper format for Pipeline usage.
	#  Removes "chr"
	#  Subtracts 10 bp from start (column 2)
	#  Adds 10 bp to stop (column 3)
	#  Removes any HapMap chromosomes

#	USAGE
	#  Get bedfile from UCSC (http://genome.ucsc.edu/cgi-bin/hgTables)
	# 1.  Chose RefSeq.
	# 2.  Paste in reference transcript numbers
	# 3.  Select output format: bed
	# 4.  Select: Coding exons
	# 5.  Import UCSC file into genaseqar01
	# 6.  Run script: $ perl BedConverterSD.pl <UCSC file>

#  Example UCSC bed output
#	chr1	76190472	76190502	NM_000016_cds_0_0_chr1_76190473_f	0	+
#	chr1	76194085	76194173	NM_000016_cds_1_0_chr1_76194086_f	0	+
#	chr2	26698995	26699185	NM_194248_cds_24_0_chr2_26698996_r	0	-
#	chr3	53837449	53837599	NM_000720_cds_44_0_chr3_53837450_f	0	+
#	chr3	53839009	53839173	NM_000720_cds_45_0_chr3_53839010_f	0	+
#	chrX	21755680	21755815	NM_014332_cds_1_0_chrX_21755681_r	0	-
#	chr15	76580186	76580286	NM_000126_cds_7_0_chr15_76580187_r	0	-
#	chr17	18062238	18062311	NM_016239_cds_51_0_chr17_18062239_f	0	+
#	chr19	1387809	1387846	NM_024407_cds_1_0_chr19_1387810_f	0	+
#	chr19	1388523	1388592	NM_024407_cds_2_0_chr19_1388524_f	0	+
#	chr22	36705326	36705441	NM_002473_cds_26_0_chr22_36705327_r	0	-
#	chr6_mann_hap4	4598440	4598494	NM_080680_cds_29_0_chr6_mann_hap4_4598441_r	0	-
#	chr6_mann_hap4	4598594	4598648	NM_080680_cds_30_0_chr6_mann_hap4_4598595_r	0	-

# Curated bed output
# 1	76190461	76190512	NM_000016_cds_0_0_chr1_76190473_f	0	+
# 1	76194074	76194183	NM_000016_cds_1_0_chr1_76194086_f	0	+
# 2	26698984	26699195	NM_194248_cds_24_0_chr2_26698996_r	0	-
# 3	53837438	53837609	NM_000720_cds_44_0_chr3_53837450_f	0	+
# 3	53838998	53839183	NM_000720_cds_45_0_chr3_53839010_f	0	+
# X	21755669	21755825	NM_014332_cds_1_0_chrX_21755681_r	0	-
# 15	76580175	76580296	NM_000126_cds_7_0_chr15_76580187_r	0	-
# 17	18062227	18062321	NM_016239_cds_51_0_chr17_18062239_f	0	+
# 19	1387798		1387856	NM_024407_cds_1_0_chr19_1387810_f	0	+
# 19	1388512		1388602	NM_024407_cds_2_0_chr19_1388524_f	0	+
# 22	36705315	36705451	NM_002473_cds_26_0_chr22_36705327_r	0	-

my $bedFile=shift; # allows typing of BedConverterSD.pl and file name
	chomp $bedFile;
	unless (open (bedFile, $bedFile) ) 
			{
    				print "\nSorry.  The file \"$bedFile\" is either misspelled or not in this directory.\n\nUSAGE: perl BedConverter.pl <your UCSC bed file> \n\n";
   					exit;
			}
print "\nStarting UCSC bed file conversion of \"$bedFile\":\n\n";	 #Screen information				
my $tmp=system ("cp $bedFile tmp.txt"); # makes temp file

system ("perl -pi -e 's/\r/\n/g' tmp.txt" ); # removes "^M" in-file to fix carriage returns
system ("sed 's/chr//' tmp.txt | sed '/track/d' > tmp2.txt"); # removes chr (genseqar01) pipe remove track line
# system ("sed 's/\\chr//' tmp.txt > tmp2.txt"); # removes chr on local Mac
system ("grep -v hap tmp2.txt > tmp.txt"); # removes all hapmap lines

print "Total number of lines in \"$bedFile\":\n";
my $OriginalLines = system ("wc -l < tmp2.txt"); # counts total number of lines in input file
print "\nNumber of lines in \"$bedFile\" that are hapmap coordinates:\n     ";
my $HapLines = system ("grep -c hap tmp2.txt"); # counts total number of "hap" lines in input file

open my $input, '<', 'tmp.txt'; # input tmp.file
open (OUT, '> curated.bed'); # required for print to file
while(<$input>)
	{
    my @split = split(/\s+/); # splits the file based on tabs
    my $start = ($split[1] - 11); # subtracts 10 bp from column 2
    my $stop = ($split[2] + 10); # adds 10 bp to column 3
	my $final = print OUT "$split[0]\t$start\t$stop\t$split[3]\t$split[4]\t$split[5]\n"; # prints out all columns tab delimited
	}

print "\nTotal number of lines in curated.bed file:\n";
my $FinalLines = system ("wc -l < curated.bed"); # counts total number of lines in curated file  This is a check--the number of lines in his file should equal the number of lines from the original file minus the hapmap lines.

# Clean up files
system ("rm tmp*"); # removes tmp files
system ("mv curated.bed /mnt/research1/projects/shale_d/bed_files/$bedFile.curated.bed"); # renames original bed file and places in bed file

print "\nFile check:\n\n";

print "Original UCSC \"$bedFile\"\n";
system ("head $bedFile");

print "\nModified bed file \"$bedFile\" curated.bed\n";
system ("head /mnt/research1/projects/shale_d/bed_files/$bedFile.curated.bed");






