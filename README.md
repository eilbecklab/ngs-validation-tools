# ngs-validation-tools

The following scripts have been useful for different steps of the mitochondrial disorders validation.  Note that these some of the scripts require other tools, such as BWA, GATK, and samtools.  Some of the scripts have not been streamlined and the coding is suboptimal.  Any programs required for these scripts can be downloaded from sourceforge.com.  

NOTE: Most of these programs will need to have directory paths modified, as these were written for internal use only.

BedCOnverter.pl			Used to create QC bed files from UCSC bed files
CoverageAndVCFfromBed.pl	Extracts all genes in supplied bed file and generates vcfs, and coverage 
				information from a bam file.
NMtset.pl			Used for transcript versioning
SingleGene.pl			Script that extracts variants from a bam with specific formatting for 
				validation.  Can be used for a single gene or panel.
Fastq2Bam.pl			Creates bam and bam.bai files from fastqs.


# ngs-validation-tools
