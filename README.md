# Genome Divergence pipeline

## Requirements

```
python 3.12.3
Snakemake 9.16.2
KMC 3.2.4
MIKE 1.0
```
Note that you must also install all required dependencies from those.

## Step 1 - Getting organism information

Argument -c is for number of threads, increase as wanted

Argument -n is for dry-run, remove for actual run

```bash
snakemake -c1 -n -s scripts/1_fetch_data/fetch_data.smk
```

## Step 2 - Getting genomic data download links

```bash
snakemake -c1 -n -s scripts/2_get_urls/data_dl.smk
```

## Step 3 - MIKE process

```bash
snakemake -c1 -n -s scripts/3_evo_distance/process_mike.smk
```
