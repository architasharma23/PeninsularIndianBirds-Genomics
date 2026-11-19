for K in 1 2 3 4 5; do
  for rep in $(seq 1 20); do
    seed=$RANDOM
    NGSadmix -likes ../GRTD_10ind_Angsd_GL_thinned_50kb.beagle.gz -K $K -P 20 -minMaf 0.05 \
      -seed $seed -o ngsadmix_K${K}_r${rep}
  done
done


##collect log-likelihoods (needed for both the raw-logL plot and ?K below)
for f in ngsadmix_K*_r*.log; do
  k=$(echo "$f" | sed -E 's/.*_K([0-9]+)_r.*/\1/')
  ll=$(grep -oP '(?<=best like=)-?[0-9.]+' "$f")
  echo -e "${k}\t${ll}"
done > logL_table.tsv   # columns: K, logL  (one row per replicate)

