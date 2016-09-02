### CREATE NM.TXT FILE FROM BED FILE

	system ("cut -f4 /mnt/research1/projects/shale_d/bed_files/514ucscCDSbed.curated.bed | sed 's/_cds.*//' > input.txt"); # extracts column 4 from tmp.txt and removes all but NM_<number>
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
	print "\nLine count input.txt (bed file) and Unique Transcripts)\n"; # printed text
	system ("wc -l input.txt UniqueTranscripts NM.txt"); # provides line count information of pre and post duplicate line removal
system ("rm input.txt count* num.txt temp.txt"); # removes unwanted files
### COMPLETE NM.TXT FILE FROM BED FILE
