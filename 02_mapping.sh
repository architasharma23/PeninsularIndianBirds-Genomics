#!/bin/bash

inpath=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/01_trimming/LTS/ #input files directory
outpath=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/LTS/ #output files directory
reffile=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/LTS/ref/RBS/GCA_020086605.1_ASM2008660v1_genomic.fna #path to indexed ref
email=vishwajagati@abs.iisertirupati.ac.in #email address for notifications

mkdir -p $outpath #create output directory

echo "starting mapping at $(date)" | mail -s "mapping started" $email

#loop through all the paired-end fastq files
for i in $inpath*_R1_paired.fastq.gz; do
    #extract the basename from the file path (for example "xyz" from "xyz_R1_paired.fastq.gz")
    file=$(basename $i _R1_paired.fastq.gz)

    echo "mapping $file with bwa mem"

    /home/birdlab/softs/bwa/bwa mem -t 10 -M -R "@RG\tID:$file\tSM:$file\tLB:IlluminaWGS\tPL:ILLUMINA" \
        $reffile \
        $inpath$file"_R1_paired.fastq.gz" \
        $inpath$file"_R2_paired.fastq.gz" | \
    /usr/local/bin/samtools view -bh - | \
    /usr/local/bin/samtools sort -@ 10 -T tmp1 -o $outpath$file"_sorted_pe.bam"

done

#email notification that the script has finished
echo "mapping completed at $(date)" | mail -s "mapping finished" $email
