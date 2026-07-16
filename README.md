# Genome Divergence Pipeline

## Requirements

```
python 3.12.3
Snakemake 9.16.2
BUSCO 6.0.0
Miniprot 0.18-r281
HMMER 3.4
Entrez E-Utilities
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
phytools 2.5-2
maps 3.4.3
ape 5.8.1
```

Note that you must also install all required dependencies from those.

Silixx is an available version of silix on the cluster.

Snakemake can be installed through uv:

```bash
uv init
uv add snakemake
```

Argument -c or --jobs is for number of threads, increase as wanted. In newer versions of Snakemake, or on the cluster, you might need to use --jobs instead. The recommended number of threads is any power of 2.

Argument -n is for dry-run, remove for actual run. Note that a dry run will not show the exact number of jobs to run for some scripts, due to the use of checkpoints. Use --quiet if you expect the run to show too much information and you just want to see the results (especially useful when working with all of eukaryota). When working on the cluster, it's best not to use --quiet as slurm will output everything as a log file for better tracking.

Argument --rerun-incomplete is recommended to add to all runs, so that Snakemake will automatically rerun all interrupted steps in case of a sudden cancel.

For some steps, argument --no-lock is recommended, as they are intended to be run multiple times at once, and Snakemake may attempt to lock the folders to prevent this, thus failing the jobs.

**Important:** Because we work with a large dataset, and running some of the tools requires a lot of memory, the script is adapted to work on multiple computers at once.
As such, for some snakemake scripts in step 2 and 3, you **must** either use the "--config max_part={number}" argument *or* set max_part={number} in the config file of the given step, and you **must** use --config partition={a number from 1 to max_part}. To use both at the same time, use --config partition={x} max_part={y}.
The script partitions the data into {max_part} equal parts and works on part number {partition}. You must run each partition, so in total on {max_part} machines (you may set max_part=1 if you have the resources required).

The scripts should be executed from working directory /your/path/to/genome_divergence_pipeline/

Four config files are to be modified for this pipeline to work:

scripts/environment_path.json contains the paths to various folders of this pipeline. **Make sure the strings end with a slash (/)** to avoid errors.

scripts/1_fetch_data/config.json defines the query to NCBI.

scripts/2_cds_extraction/config.json contains only the partition number and maximum number of partitions, as mentioned above.

scripts/3_ds_computation/config.json contains the partition number, the maximum number of partitions, and a threshold value for each taxonomic level between Genus and Phylum. Default values are 0.1, 0.2, 0.3, 0.5, 0.5.

## Script folder 1 - Data fetch

### Step 1 - Getting organism information

This step is not very costly.

This step takes in an NCBI query from the config file and gathers data from all organisms in the query.

Note: very large queries may fail as there isn't enough space in the command line. To run on all of Eukaryota, please use the query 'Eukaryota'.

```bash
uv run snakemake --jobs {k} -n --config partition=1 -s scripts/1_fetch_data/fetch_data.smk
```

### Step 2 - Getting genomic data download links

This step is not very costly.

This step gets the download links of each species' genomic data, as well as protein and annotation data if available.

```bash
uv run snakemake --jobs {k} -n --config partition=1 -s scripts/1_fetch_data/data_dl.smk
```

## Script folder 2 - CDS extraction

### Step 3 - Separation of curated and uncurated data

This step is not very costly.

This step prepares the folders so as to separate unannotated and annotated data for BUSCO execution.

```bash
uv run snakemake -n -s scripts/2_cds_extraction/separate_curated_uncurated.smk
```

### Step 4a - Extraction of CDS of BUSCO genes from unannotated data

This step runs BUSCO on all unnanotated genomes, and extracts the CDS of BUSCO genes for each species using BUSCO's generated GFFs.

Due to the large number of species and the lengthy runtime, it is advised to partition this step. Also note this step uses a lot of memory.

```bash
uv run snakemake --jobs {k} -n -s scripts/2_cds_extraction/module_busco_extraction_genome.smk --config partition={x} max_part={y}
```

### Step 4b - Extraction of CDS of BUSCO genes from annotated data

This step runs BUSCO on all annotated genomes, and extracts the CDS of BUSCO genes for each species using protein IDs and GFFs.

```bash
uv run snakemake --jobs {k} -n -s scripts/2_cds_extraction/module_busco_extraction_protein.smk
```

### Step 5 - Concatenation of BUSCO data

This step is not very costly.

This step concatenates all extracted CDS into a single file, used for the Seaview analysis.

```bash
uv run snakemake -n -s scripts/2_cds_extraction/process_cds_extraction.smk
```

## Script folder 3 - Seaview analysis and dS computation per taxonomic level

For this folder, a set of three scripts must be run for each taxonomic level from Genus to Class, with Phylum also being possible but not necessary.

Therefore, replace "clade" in the following scripts with any of the taxonomic levels between Genus, Family, Order, Class and Phylum. They must be run in that order (i.e. you must have run all scripts for Genus before running Family.)

The scripts also require a file called "list_species_to_process" in the results folder, containing a list of all accession numbers of species you want to compute the dS for. If you're working with all species in your initial query, you may simply extract the accession numbers from data/resources/organisms_data.

Finally, step 7 requires a path to the Seaview executable in the script scripts/3_ds_computation/csh/Aln_dNdS.csh. This path must be changed to your own path to Seaview.

### Step 6 - Creating list of pairs

This step is not very costly.

This step takes in the taxonomy file and concatenated BUSCO CDS data, and returns a list of pairs to align against one another. In the case of Genus, it also generates the BLAST database for those BUSCO genes.

```bash
uv run snakemake -n -s scripts/3_ds_computation/process_{clade}_pair_list.smk
```

### Step 7 - Seaview analysis and dS computation

This step takes in the BUSCO CDS data and the pairings, and returns an alignment analysis performed by Seaview.

Because of the potential number of pairs, Snakemake may take a lot of time to generate the DAG of jobs for this scripts. Therefore, heavy partitioning is advised.

The argument --nolock is used because Snakemake will often attempt to lock the folder when multiple partitions are run at once, thus failing the jobs.

```bash
uv run snakemake --jobs {k} -n -s scripts/3_ds_computation/process_{clade}_ds_calculation.smk --config partition={x} max_part={y} --nolock
```

### Step 8 - Cluster species on dS and find representative species

This step takes in the computed dS of all alignments at the current taxonomic level, and returns clusters of closely-related species based on a dS threshold, as well as a representative species for each cluster.

Make sure to specify the max_part config parameter, as it is used to concatenate all partitioned results of the previous script.

```bash
uv run snakemake --jobs {k} -n -s scripts/3_ds_computation/process_{clade}_get_representatives.smk --config max_part={y}
```

## Folder hierarchy:

Names between [] are temporary and deleted during process.

```
.
+-- busco_downloads                                         # BUSCO data for eukaryota 
+-- data
|   +-- assemblies                                          # Note: Data currently downloaded on a bank instead
|   |   +== {accession}
|   |       +-- [genomic.fna]                               # Genomic fasta file
|   |       +-- [genomic.gff]                               # Annotation file (only if annotated)
|   |       +-- [protein.faa]                               # Protein fasta file (only if annotated)
|   |       +-- url_genomic.fna.txt                         # Download links to data
|   +-- resources
|       +-- [rooted_extraction]
|       +-- organisms_data                                  # Full data of organisms
|       +-- ncbi_eukaryota_dataset.taxonomy                 # Taxonomy file for eukaryota
|       +-- nodes.dmp                                       # Genetic code file
+-- results
|   +-- BUSCO
|   |   +-- extracted_buscos
|   |   |   +== {accession}-{busco id}.fasta                # Sequence for busco {busco id} and species {accession}
|   |   +-- genome
|   |   |   +== {accession}
|   |   |       +-- run_eukaryota_odb12
|   |   |           +-- busco_sequences
|   |   |           |   +-- single_copy_busco_sequences
|   |   |           |       +== {busco id}.gff              # Busco annotation data
|   |   |           |   +-- multi_copy_busco_sequences
|   |   |           |       +== {busco id}.gff              # Busco annotation data
|   |   |           +-- full_table.tsv                      # Data table
|   |   +-- protein
|   |   |   +== {accession}
|   |   |       +-- run_eukaryota_odb12
|   |   |           +-- full_table.tsv                      # Data table
|   |   +-- busco_full.fa                                   # All combined buscos in single file
|   +-- {clade}_Clustering
|   |   +== cluster_{x}_matrix.txt                          # dS matrix for step 8
|   |   +== cluster_{x}_representative_species              # Representative species of cluster x
|   +-- seaview_alignment
|   |   +-- Alignment_Summaries
|   |   |   +== {clade}_level_{x}-{y}_full_alignment.dNdS   # Partitioned dS for pairs in taxonomic level {clade}
|   |   |   +== {clade}_level_full_alignment.dNdS           # Total data of dS for pairs in taxonomic level {clade}
|   |   +-- Per_BUSCO_Alignments
|   |       +== {accession_1}-{accession_2}
|   |           +-- busco_pairs                             # Pairs of BUSCO genes for Seaview analysis
|   |           +-- full_alignment.dNdS                     # Summarized seaview alignment for given pair of species
|   |           +-- per_busco_alignment.dNdS                # Seaview alignment of pair of species for each BUSCO gene
|   +== busco_pairs_{clade}                                 # Full list of pairs of BUSCO genes to align for step 7
|   +== {clade}_close_species_pairs                         # Pairs of species which passed the dS threshold
|   +== {clade}_clustered_species                           # Species and their Silixx-given cluster 
|   +== {clade}_full_representative_species                 # Representative species and orphan species for given taxonomic level
|   +== {clade}_list_processed_species                      # List of all species which passed the threshold, for getting number of species for Silixx
|   +-- full_species_list                                   # Species to process at Genus level
|   +== list_orphans_{clade}                                # Species with less than two other members in their clade
|   +== list_pairs_{clade}                                  # Pairs of species to process at {clade} level
|   +-- list_species_to_process                             # List of species to process through the pipeline (mostly for step 4)
|   +-- list_species_with_no_buscos                         # Species to process which end up having no BUSCO gene in the dataset
+-- scripts
|   +-- 1_fetch_data
|   |   +-- python
|   |   |   +-- xml_reader.py
|   |   |   +-- xml_rewrite.py
|   |   +-- config.json                                     # Defines query
|   |   +-- data_dl.smk                                     # Script 2
|   |   +-- fetch_data.smk                                  # Script 1
|   +-- 2_cds_extraction
|   |   +-- python
|   |   |   +-- extract_genomic_cds.py
|   |   |   +-- extract_protein_cds.py
|   |   |   +-- extract_sequences_protein.py
|   |   |   +-- filter_isoforms.py
|   |   +-- config.json                                     # Defines number of partitions and max partition
|   |   +-- module_busco_extraction_genome.smk              # Script 4a
|   |   +-- module_busco_extraction_protein.smk             # Script 4b
|   |   +-- module_get_faa.smk
|   |   +-- module_get_fna.smk
|   |   +-- module_get_gff.smk
|   |   +-- process_cds_extraction.smk                      # Script 5
|   |   +-- separate_curated_uncurated.smk                  # Script 3
|   +-- 3_ds_computation
|   |   +-- python
|   |   |   +-- cluster_species.py
|   |   |   +-- create_busco_pairs.py
|   |   |   +-- filter_clusters.py
|   |   |   +-- filter_pairs.py
|   |   |   +-- generate_matrix.py
|   |   |   +-- generate_pairs.py
|   |   |   +-- median_dn_ds.py
|   |   |   +-- separate_by_pair.py
|   |   +-- config.json                                     # Defines number of partitions, max partition and dS thresholds
|   |   +-- process_class_ds_calculation.smk                # Script 7 Class
|   |   +-- process_class_get_representatives.smk           # Script 8 Class
|   |   +-- process_class_pair_list.smk                     # Script 6 Class
|   |   +-- process_family_ds_calculation.smk               # Script 7 Family
|   |   +-- process_family_get_representatives.smk          # Script 8 Family
|   |   +-- process_family_pair_list.smk                    # Script 6 Family
|   |   +-- process_genus_ds_calculation.smk                # Script 7 Genus
|   |   +-- process_genus_get_representatives.smk           # Script 8 Genus
|   |   +-- process_genus_pair_list.smk                     # Script 6 Genus
|   |   +-- process_order_ds_calculation.smk                # Script 7 Order
|   |   +-- process_order_get_representatives.smk           # Script 8 Order
|   |   +-- process_order_pair_list.smk                     # Script 6 Order
|   |   +-- process_phylum_ds_calculation.smk               # Script 7 Phylum
|   |   +-- process_phylum_get_representatives.smk          # Script 8 Phylum
|   |   +-- process_phylum_pair_list.smk                    # Script 6 Phylum
|   +-- environment_path.json
+-- README.md
```

The data folder contains all data for the analysis. **Note that the nodes.dmp file does not come in the repository, as it is too large, you must get it from the "taxdump" files of NCBI.** You may need to regenerate a new taxonomy file when adding new species to the dataset: make sure to respect naming and formatting, so as to not cause any issues with the scripts.

The scripts folder contains all of the scripts used by the pipeline, as well as config files.

The results folder contains all generated files, including all BUSCO gene CDS, all Seaview-computed dN, dS and dN/dS, and lists of pairs and clusters for each taxonomic level.

The busco_downloads folder contains the BUSCO eukaryota dataset.

### Known issue

Updating busco_full.fa may cause Snakemake to want to run all pairs again for the final step. To prevent this, either touch busco_full.fa to give it an earlier date of creation, or modify all versions of script 7 (ds_calculation) to remove the dependency on busco_full.fa.