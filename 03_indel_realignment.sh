#!/bin/bash

#samtools index
samtools faidx /media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/ref/GCA_054084135.1_bCopSec1.hap2_genomic.fna

##generating .dict file
java -Xmx16g -jar ~/softs/picard-2.27.5/picard.jar CreateSequenceDictionary \
    R=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/ref/GCA_054084135.1_bCopSec1.hap2_genomic.fna \
    O=/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/ref/GCA_054084135.1_bCopSec1.hap2_genomic.dict


inpath="/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/rmdup/"
outpath="/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/RI/"
email="vishwajagati@labs.iisertirupati.ac.in"  #Your email address
ref="/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/ref/GCA_054084135.1_bCopSec1.hap2_genomic.fna"

mkdir -p "$outpath"

echo "starting indel realignment processing at $(date)" | mail -s "indel realignment started" "$email"

#function to run GATK indel realignment for each sample. function has some issues with using $paths so explicitly state the paths in the sections under "". 
realign_sample() {
    filepath=$1
	file=$(basename "$filepath" "_sorted_rmdup.bam")
    echo "RealignerTargetCreator targets for ${file}";
    
    #RealignerTargetCreator
    java -Xmx16g -jar /home/birdlab/softs/gatk-3.6/GenomeAnalysisTK.jar -T RealignerTargetCreator \
    -R "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/ref/GCA_054084135.1_bCopSec1.hap2_genomic.fna" \
    -I "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/rmdup/"$file"_sorted_rmdup.bam" \
    -o "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/RI/"$file"_sorted_rmdup.intervals";
    
    echo "IndelRealigner for ${file}";
    
    #IndelRealigner
    java -Xmx16g -jar /home/birdlab/softs/gatk-3.6/GenomeAnalysisTK.jar -T IndelRealigner \
    -R "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/ref/GCA_054084135.1_bCopSec1.hap2_genomic.fna" \
    -I "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/rmdup/"$file"_sorted_rmdup.bam" \
    -targetIntervals "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/RI/"$file"_sorted_rmdup.intervals" \
    -o "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/RI/"$file"_RI.bam";
    
    echo "indexing ${file} bam";
    
    #indexing bam file
    samtools index "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/IR/RI/"$file"_RI.bam";
    
    echo "finished ${file}";
}

export -f realign_sample  #make the function for parallel

#run realignment in parallel
find "$inpath" -name "*_sorted_rmdup.bam" | parallel -j 20 realign_sample

echo "indel realignment completed at $(date)" | mail -s "indel realignment completed" "$email"
