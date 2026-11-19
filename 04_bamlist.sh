#!/bin/bash

#directory containing bams
bam_dir="/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/LTS/RI/"

#output file where the list of bams paths will be saved
output_file="/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/02_mapping/LTS/RI/bamlist.txt"

#find all bams and save their full paths to the output file
find "$bam_dir" -type f -name "*_RI.bam" > "$output_file"

