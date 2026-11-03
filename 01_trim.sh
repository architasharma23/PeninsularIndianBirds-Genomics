#!/bin/bash

softpath=/home/birdlab/softs/Trimmomatic-0.39/ #software directory
inpath=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/00_raw/LTS/ #input files directory
outpath=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/01_trimming/LTS/ #outputs directory
trimpath=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/01_trimming/LTS/trim-logs/ #trimlog directory
email=vishwajagati@labs.iisertirupat.ac.in     #email address for notifications

mkdir -p $outpath #create output directory

echo "starting trimming at $(date)" | mail -s "trimming started" $email

for i in $inpath*_R1_001.fastq.gz; do
	file=$(basename $i _R1_001.fastq.gz);
	echo $file;
	/usr/lib/jvm/java-17-openjdk-amd64/bin/java -jar $softpath"trimmomatic-0.39.jar" PE \
		-phred33 -threads 10 -summary $trimpath$file".txt" \
		$inpath$file"_R1_001.fastq.gz" $inpath$file"_R2_001.fastq.gz" \
		$outpath$file"_R1_paired.fastq.gz" $outpath$file"_R1_unpaired.fastq.gz" \
		$outpath$file"_R2_paired.fastq.gz" $outpath$file"_R2_unpaired.fastq.gz" \
		ILLUMINACLIP:$softpath"adapters/TruSeq3-PE.fa":2:30:10:2:True LEADING:3 TRAILING:3 MINLEN:36;
	done

echo "trimming completed at $(date)" | mail -s "trimming finished" $email
