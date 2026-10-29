#!/bin/bash

source /home/birdlab/miniconda3/etc/profile.d/conda.sh
conda activate getorganelle

set -euo pipefail
RAWDIR="/mnt/SERB_NAS_Biogeography/Archita/01_trimmed/01_trimming/BRF"
OUTBASE="/mnt/hdd/vishwa/BRF"
THREADS=12
mkdir -p "$OUTBASE"

samples=(
"60207404527-388607-NCGM-4418_L001"
"60207404528-552271-NCGM-4418_L001"
"60207404529-777456-NCGM-4418_L001"
"60207404530-777460-NCGM-4418_L001"
)

for SAMPLE in "${samples[@]}"; do

    R1="${RAWDIR}/${SAMPLE}_R1_paired.fastq.gz"
    R2="${RAWDIR}/${SAMPLE}_R2_paired.fastq.gz"

    SAMPLE_OUTDIR="${OUTBASE}/${SAMPLE}"

 if [[ ! -f "$R1" ]]; then
        echo
        echo "WARNING: Missing R1 for ${SAMPLE}"
        echo "Expected: ${R1}"
        echo "Skipping..."
        continue
    fi

    if [[ ! -f "$R2" ]]; then
        echo
        echo "WARNING: Missing R2 for ${SAMPLE}"
        echo "Expected: ${R2}"
        echo "Skipping..."
        continue
    fi

    mkdir -p "$SAMPLE_OUTDIR"

    get_organelle_from_reads.py \
        -1 "$R1" \
        -2 "$R2" \
        -o "$SAMPLE_OUTDIR" \
        -F animal_mt \
        -t "$THREADS" \
        --overwrite

done
