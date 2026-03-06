# Genome Divergence Pipeline

## Requirements

```
python 3.12.3
Snakemake 9.16.2
KMC 3.2.4
MIKE 1.0
BUSCO 6.0.0
Seaview 5.1
silixx 1.2.10
R 4.4.3
```
### Python packages

```
biopython 1.86
pandas 3.0.0
```

### R packages

```
stringr 1.6.0
```

Note that you must also install all required dependencies from those.

KMC and MIKE are compiled from their git repositories:

https://github.com/refresh-bio/KMC

https://github.com/Argonum-Clever2/mike

Their command line executables **must** be located in either **~/bin** or **~/.local/bin.**, or added to your PATH.

Silixx is an available version of silix on the cluster.

Snakemake can be installed through uv:

```bash
uv init
uv add snakemake
```

Argument -c or --jobs is for number of threads, increase as wanted. In newer versions of snakemake, you might need to use --jobs instead. The recommended number of threads is 2. Do note that some tools will require at least 12GB of memory *per thread*. That number can be modified in scripts/2_analysis_pipeline/config.json if you cannot afford that much memory, or if you can afford more.

Argument -n is for dry-run, remove for actual run. Use --quiet if you expect the run to show too much information and you just want to see the results (especially useful when working with all of eukaryota). When working on the cluster, it's best not to use --quiet as slurm will output everything as a log file for better tracking.

**Important:** Because we work with a large dataset, and running some of the tools requires a lot of memory, the script is adapted to work on multiple computers at once.
As such, for each snakemake run up to Step 3 *included*, you **must** either use the "--config max_part={number}" argument *or* set max_part={number} in scripts/1_fetch_data/config.json, and you **must** use --config partition={a number from 1 to max_part}.
The script partitions the data into {max_part} equal parts to work on each individually. You must run each partition, so in total on {max_part} machines (you may set max_part=1 if you have the resources required).

The scripts should be executed from working directory /your/path/to/genome_divergence_pipeline/

Four config files are to be modified for this pipeline to work:

scripts/environment_path.json contains the paths to various folders of this pipeline. **Make sure the strings end with a slash (/)** to avoid errors.

scripts/1_fetch_data/config.json defines the query to NCBI, as well as the total number of partitions and the current partition. For the latter, prefer using --config partition={number} in the snakemake command line.

scripts/2_analysis_pipeline/config.json contains 4 variables. k is the length of kmers for the kmer count step. Recommended value is 21: any lower is too inaccurate. min_count and max_count are used in the KMC command line (refer to KMC documentation); min_count must remain 1, but you may adjust max_count (recommended is 5). mem is the amount of memory used in GB by the process, 12 is base.

## Script folder 1 - Data fetch

### Step 1 - Getting organism information

This step is not very costly.

This step takes in an NCBI query from the config file and gathers data from all organisms in the query.

Note: very large queries may fail as there isn't enough space in the command line. To run on all of Eukaryota, please use the query 'Eukaryota'.

```bash
uv run snakemake --jobs 2 -n --config partition=1 -s scripts/1_fetch_data/fetch_data.smk
```

### Step 2 - Getting genomic data download links

This step is not very costly.

This step gets the download links of each species' genomic data, as well as protein and annotation data if available.

```bash
uv run snakemake --jobs 2 -n --config partition=1 -s scripts/1_fetch_data/data_dl.smk
```

## Script folder 2 - Distance matrix generation

### Step 3 - KMC process

This step runs a kmer count algorithm on all genomes and returns hash files used later on for matrix generation.

```bash
uv run snakemake --jobs 2 -n --config partition=1 -s scripts/2_analysis_pipeline/process_kmc.smk
```

### Step 4 - Clade infering

**Only** run this once you have run step 3 on all partitions.

This step is not very costly.

This step takes all hash files and a taxonomy dataset, and infers all clades that the species will be filtered into.

A species will be filtered in the largest clade of which there are less than 1000 members in the query.

```bash
uv run snakemake -n -s scripts/2_analysis_pipeline/module_get_clade.smk
```

### Step 5 - Distance matrix calculation

This step takes all hash file lists for each clade, and runs a distance matrix algorithm on each clade.

```bash
uv run snakemake --jobs 2 -n -s scripts/2_analysis_pipeline/process_distance_matrix.smk
```

## Script folder 3 - CDS extraction

### Step 6 - Separation of curated and uncurated data

This step is not very costly.

This step prepares the folders so as to separate unannotated and annotated data for BUSCO execution.

```bash
uv run snakemake -n -s scripts/3_cds_extraction/separate_curated_uncurated.smk
```

### Step 7a - Extraction of CDS of BUSCO genes from unannotated data

This step runs BUSCO on all unnanotated genomes, and extracts the CDS of BUSCO genes for each species using BUSCO's generated GFFs.

```bash
uv run snakemake --jobs 2 -n -s scripts/3_cds_extraction/module_busco_extraction_genome.smk
```

### Step 7b - Extraction of CDS of BUSCO genes from annotated data

This step runs BUSCO on all annotated genomes, and extracts the CDS of BUSCO genes for each species using protein IDs and GFFs.

```bash
uv run snakemake --jobs 2 -n -s scripts/3_cds_extraction/module_busco_extraction_protein.smk
```

### Step 8 - Concatenation of BUSCO data

This step is not very costly.

This step concatenates all extracted CDS into a single file, used for the Seaview analysis.

```bash
uv run snakemake -n -s scripts/3_cds_extraction/process_cds_extraction.smk
```

## Script folder 4 - Seaview analysis

### Step 9 - Clustering of close species

This step is not very costly.

This step takes in the distance matrix of each clade, and returns a clustering of species in each clade, formatted into pairings of species.

```bash
uv run snakemake -n -s scripts/4_seaview_analysis/process_clustering.smk
```

### Final step - Seaview analysis

This step takes in the BUSCO CDS data and the pairings, and returns an alignment analysis performed by Seaview.

```bash
uv run snakemake -n -s scripts/4_seaview_analysis/process_seaview.smk
```

## Folder hierarchy:

Names between [] are temporary and deleted during process.

```
.
+-- busco_downloads
+-- data
|   +-- assemblies
|   |   +== {accession}
|   |       +-- [genomic.fna]
|   |       +-- [genomic.gff]
|   |       +-- [genomic.faa]
|   |       +-- genomic.fna.txt
|   +-- [KMC]
|   +-- BUSCO
|   |   +-- extracted_buscos
|   |   |   +== {accession}-{busco id}.fasta
|   |   +-- genome
|   |   |   +== {accession}
|   |   |       +-- run_eukaryota_odb12
|   |   |           +-- busco_sequences
|   |   |           |   +-- single_copy_busco_sequences
|   |   |           |       +== {busco id}.gff
|   |   |           +-- full_table.tsv
|   |   +-- protein
|   |   |   +== {accession}
|   |   |       +-- run_eukaryota_odb12
|   |   |           +-- full_table.tsv
|   |   +-- busco_full.fa
|   +-- minhash
|   |   +-- hashlists
|   |   |   +== {clade}_hashlist.txt
|   |   +== kmc_{accession}.minhash.jac
|   +-- resources
|       +-- [rooted_extraction]
|       +-- organism_data
|       +== {partition}_organism_data
|       +-- ncbi_eukaryota_dataset.taxonomy
+-- results
|   +== {clade}
|   |   +-- dist.txt
|   |   +-- hr_dist.txt
|   |   +-- pair_list
|   |   +-- [species_pair]
|   |   +-- [clustered_species]
|   +-- total_pair_list
|   +-- full_alignment.KaKs
+-- scripts
|   +-- 1_fetch_data
|   |   +-- python
|   |   |   +-- partition_organisms_data.py
|   |   |   +-- xml_reader.py
|   |   |   +-- xml_rewrite.py
|   |   +-- config.json
|   |   +-- data_dl.smk
|   |   +-- fetch_data.smk
|   +-- 2_analysis_pipeline
|   |   +-- python
|   |   |   +-- get_clade.py
|   |   |   +-- hr_dist.py
|   |   |   +-- write_filelist.py
|   |   |   +-- write_hashlist.py
|   |   +-- Rscript
|   |   |   +-- get_clusters.R
|   |   +-- config.json
|   |   +-- module_get_clade.smk
|   |   +-- process_distance_matrix.smk
|   |   +-- process_kmc.smk
|   +-- 3_cds_extraction
|   |   +-- python
|   |   |   +-- extract_genomic_cds.py
|   |   |   +-- extract_protein_cds.py
|   |   |   +-- extract_sequences_protein.py
|   |   |   +-- filter_isoforms.py
|   |   +-- module_busco_extraction_genome.smk
|   |   +-- module_busco_extraction_protein.smk
|   |   +-- module_get_faa.smk
|   |   +-- module_get_fna.smk
|   |   +-- module_get_gff.smk
|   |   +-- process_cds_extraction.smk
|   |   +-- separate_curated_uncurated.smk
|   +-- 4_seaview_analysis
|   |   +-- python
|   |   |   +-- cluster_species.py
|   |   |   +-- create_pairs.py
|   |   +-- config.json
|   |   +-- process_clustering.smk
|   |   +-- process_seaview.smk
|   +-- environment_path.json
+-- README.md
```

The data folder contains all data for the analysis, most of which is held temporarily and deleted at the earliest convenience to save disk space.

The scripts folder contains all of the scripts used by the pipeline, as well as config files.

The results folder contains the distance matrix and its human readable version, as well as the dNdS analysis from Seaview.

The busco_downloads folder contains the BUSCO eukaryota dataset.