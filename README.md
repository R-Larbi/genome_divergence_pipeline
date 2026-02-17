# Genome Divergence Pipeline

## Requirements

```
python 3.12.3
Snakemake 9.16.2
KMC 3.2.4
MIKE 1.0
```
Note that you must also install all required dependencies from those.
KMC and MIKE are compiled from their git repositories:
https://github.com/refresh-bio/KMC
https://github.com/Argonum-Clever2/mike
Their command line executables **must** be located in either **~/bin** or **~/.local/bin.**, or added to your PATH.

Snakemake can be installed through uv:

```bash
uv init
uv add snakemake
```

Argument -c or --jobs is for number of threads, increase as wanted. In newer versions of snakemake, you might need to use --jobs instead. The recommended number of threads is 2. Do note that some tools will require at least 12GB of memory *per thread*, so adapt as needed.

Argument -n is for dry-run, remove for actual run. Use --quiet if you expect the run to show too much information and you just want to see the results (especially useful when working with all of eukaryota).

**Important:** Because we work with a large dataset, and running some of the tools requires a lot of memory, the script is adapted to work on multiple computers at once.
As such, for each snakemake run up to Step 3 *included*, you **must** use the --config argument followed by partition={a number from 1 to 10}.
The script partitions the data into 10 equal parts to work on each individually. You must run each partition, so in total on 10 machines.

The scripts should be executed from working directory /your/path/to/genome_divergence_pipeline/

## Step 1 - Getting organism information

This step is better run on a local machine, as it is not very costly.

```bash
uv run snakemake -c2 -n --config partition=1 -s scripts/1_fetch_data/fetch_data.smk
```

## Step 2 - Getting genomic data download links

This step is better run on a local machine, as it is not very costly.

```bash
uv run snakemake -c2 -n --config partition=1 -s scripts/1_fetch_data/data_dl.smk
```

## Step 3 - KMC process

```bash
uv run snakemake -c2 -n --config partition=1 -s scripts/2_analysis_pipeline/process_kmc.smk
```

## Step 4 - Distance matrix calculation

**Only** run this once you have run step 3 on all partitions.

```bash
uv run snakemake -c2 -n -s scripts/2_analysis_pipeline/process_distance_matrix.smk
```

## Folder hierarchy:

```
.
+-- data
|   +-- assemblies
|   +-- KMC
|   +-- minhash
|   +-- resources
+-- results
|   +-- dist.txt
|   +-- hr_dist.txt
+-- scripts
|   +-- 1_fetch_data
|   |   +-- python
|   |   |   +-- xml_reader.py
|   |   |   +-- xml_rewrite.py
|   |   +-- config.json
|   |   +-- data_dl.smk
|   |   +-- fetch_data.smk
|   +-- 2_analysis_pipeline
|   |   +-- python
|   |   |   +-- clustering.py
|   |   |   +-- extract_sequences_positions.py
|   |   |   +-- extract_sequences.py
|   |   |   +-- filter_isoforms.py
|   |   |   +-- hr_dist.py
|   |   |   +-- write_filelist.py
|   |   |   +-- write_hashlist.py
|   |   +-- config.json
|   |   +-- process_kmc.smk
|   |   +-- process_distance_matrix.smk
|   +-- environment_path.json
+-- README.md
```

The data folder contains all data for the analysis, most of which is held temporarily and deleted at the earliest convenience to save disk space.

The scripts folder contains all of the scripts used by the pipeline, as well as config files. Folder 1_fetch_data is better run on a local machine, while 2_analysis_pipeline contains the costly processes and should be run on the cluster.

The results folder contains the distance matrix and its human readable version.