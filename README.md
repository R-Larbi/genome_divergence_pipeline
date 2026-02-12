# Genome Divergence pipeline

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
Their command line executables **must** be located in either **~/bin** or **~/.local/bin.**

Snakemake can be installed through uv:

```bash
uv init
uv add snakemake
```

Argument -c is for number of threads, increase as wanted. In newer versions of snakemake, you might need to use --jobs instead.

Argument -n is for dry-run, remove for actual run. Use --quiet if you expect the run to show too much information and you just want to see the results (especially useful when working with all of eukaryota).

## Step 1 - Getting organism information

```bash
uv run snakemake -c1 -n -s scripts/1_fetch_data/fetch_data.smk
```

## Step 2 - Getting genomic data download links

```bash
uv run snakemake -c1 -n -s scripts/2_get_urls/data_dl.smk
```

## Step 3 - MIKE process

```bash
uv run snakemake -c1 -n -s scripts/3_evo_distance/process_mike.smk
```

## Folder hierarchy:

```
.
+-- data
|   +-- assemblies
|   +-- KMC
|   +-- minhash
|   +-- resources
+-- scripts
|   +-- 1_fetch_data
|   |   +-- python
|   |   |   +-- xml_reader.py
|   |   |   +-- xml_rewrite.py
|   |   +-- config.json
|   |   +-- fetch_data.smk
|   +-- 2_get_urls
|   |   +-- data_dl.smk
|   +-- 3_evo_distance
|   |   +-- python
|   |   |   +-- clustering.py
|   |   |   +-- hr_dist.py
|   |   |   +-- write_filelist.py
|   |   |   +-- write_hashlist.py
|   |   +-- config.json
|   |   +-- process_mike.smk
|   +-- environment_path.json
+-- README.md
```