#!/bin/bash

email="vishwajagati@labs.iisertirupati.ac.in"
ref="/mnt/SERB_NAS_Biogeography/Naman/Ch2/03_mapping/ZOPA/ref/ZOLA/GCA_965231245.1_bZosLat1.hap2.1_genomic.fna"
bamlist="./bamlist.txt"
outpath="./"
subsample_dir="${outpath}/subsampled_bams"
TARGET_DEPTH=5
N_IND=14
THREADS=30

mkdir -p "$outpath" "$subsample_dir"
echo "starting IWE subsampling + angsd at $(date)" | mail -s "IWE angsd started" "$email"

genome_size=$(samtools view -H "$(head -1 "$bamlist")" | \
    awk '/^@SQ/{match($0,/LN:([0-9]+)/,a); s+=a[1]} END{print s}')

subsampled_bamlist="${outpath}/subsampled_bamlist.txt"
> "$subsampled_bamlist"

while IFS= read -r bam; do
    sample=$(basename "$bam" .bam)
    sub_bam="${subsample_dir}/${sample}_sub${TARGET_DEPTH}x.bam"

    if [[ -f "${sub_bam}.bai" ]]; then
        echo "[SKIP] $sample already subsampled"
        echo "$sub_bam" >> "$subsampled_bamlist"
        continue
    fi

    mapped=$(samtools flagstat "$bam" | awk '/mapped \(/{print $1; exit}')
    read_len=$(samtools view "$bam" | head -1000 | \
        awk '{sum+=length($10)} END{print int(sum/NR)}')
    mean_depth=$(echo "scale=4; $mapped * $read_len / $genome_size" | bc)
    frac=$(echo "scale=6; $TARGET_DEPTH / $mean_depth" | bc)

    if (( $(echo "$frac >= 1.0" | bc -l) )); then
        echo "[INFO] $sample depth (${mean_depth}x) <= target, using original BAM"
        echo "$bam" >> "$subsampled_bamlist"
    else
        echo "[INFO] subsampling $sample (${mean_depth}x) to fraction $frac"
        samtools view -bh \
            --subsample "$frac" \
            --subsample-seed 42 \
            -@ "$THREADS" \
            -o "$sub_bam" "$bam"
        samtools index "$sub_bam"
        echo "$sub_bam" >> "$subsampled_bamlist"
    fi

done < "$bamlist"

echo "subsampling complete at $(date)"

MAX_DEPTH=$(echo "$N_IND * $TARGET_DEPTH * 2" | bc) 
MIN_DEPTH=$(echo "$N_IND * 1" | bc)                 
MIN_IND=$(echo "$N_IND * 7 / 10" | bc)             

echo "[INFO] setMinDepth=$MIN_DEPTH setMaxDepth=$MAX_DEPTH minInd=$MIN_IND"

angsd -GL 2 -doGlf 2 -doMajorMinor 1 \
    -minInd $MIN_IND \
    -doMaf 1 -doGeno 8 -doPost 1 -skipTriallelic 1 \
    -minMapQ 20 -minQ 20 -SNP_pval 2e-6 -minMaf 0.05 \
    -setMinDepth $MIN_DEPTH -setMaxDepth $MAX_DEPTH \
    -uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 \
    -doBcf 1 --ignore-RG 0 \
    -C 50 -baq 1 -doCounts 1 \
    -out "${outpath}/IWE_14ind_Angsd_GL_sub${TARGET_DEPTH}x" \
    -nThreads "$THREADS" \
    -bam "$subsampled_bamlist" \
    -ref "$ref"

echo "IWE angsd completed at $(date)" | mail -s "IWE angsd completed" "$email"
