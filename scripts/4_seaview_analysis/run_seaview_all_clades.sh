#!/bin/bash

for clade in results/Clades/*;
do
    echo $(basename $clade)
    snakemake -c8 -s scripts/4_seaview_analysis/process_seaview_per_clade.smk --config clade=$(basename $clade) --resources mem_gb=25 --rerun-incomplete --scheduler greedy
done