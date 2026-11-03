#!/bin/bash

inpath="/media/birdlab/myPassport/Naman/Chapter2/genomics/3_mapping/Zopa/"
outpath="/media/birdlab/myPassport/Naman/Chapter2/genomics/3_mapping/Zopa/bamqc/"
email="naman.goyal@students.iisertirupati.ac.in"  #email address

mkdir -p "$outpath" #create output directory

# Send email notification that the script has started
echo "starting bamqc processing at $(date)" | mail -s "bamqc started" "$email"

#function bamqc for each 
run_bamqc() {
    bam_file="$1"
    file=$(basename "$bam_file" "_sorted_pe.bam")
    file_outdir="${outpath}${file}_bamqc"

    echo "running bamqc for $bam_file..."
    
    #check if bam file exists
    if [ ! -f "$bam_file" ]; then
        echo "Error: bam file $bam_file not found."
        echo "Error: bam file $bam_file not found at $(date)" | mail -s "error in bamqc: $file" "$email"
        return 1
    fi

    #qualimap
    qualimap bamqc -bam "$bam_file" -outfile "${file}.pdf" -outdir "$file_outdir" -nt 20
    
    # Check if BAMQC ran successfully
    if [ $? -ne 0 ]; then
        echo "error processing $file. Skipping this file."
        echo "error processing $file at $(date)" | mail -s "error in bamqc: $file" "$email"
    else
        echo "done with $file"
    fi
}

export -f run_bamqc  #export function for parallel

#use GNU parallel to process multiple files at a time
find "$inpath" -name "*_sorted_pe.bam" | \
    parallel -j 2 run_bamqc

echo "bamqc processing completed at $(date)" | mail -s "bamqc processing finished" $email
