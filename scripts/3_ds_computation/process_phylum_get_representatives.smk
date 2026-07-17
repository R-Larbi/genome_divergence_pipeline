import json
import glob
import os

configfile: "scripts/3_ds_computation/config.json"
part     = config["partition"]
max_part = config["max_part"]
threshold = config["phylum_threshold"]

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

rule all:
    input:
        pathResults + "phylum_full_representative_species"

rule concatenate:
    output:
        pathResults + "seaview_alignment/Alignment_Summaries/phylum_level_full_alignment.dNdS"
    shell:
        """
        echo -e "Species 1\tSpecies 2\tmedian dN\tmedian dS\tmedian dN/dS\tnb busco genes" > {output}
        for f in {pathResults}seaview_alignment/Alignment_Summaries/phylum_level_*-*_full_alignment.dNdS;
        do
            tail -n+2 $f
        done >> {output}
        """


rule filter_phylum:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/phylum_level_full_alignment.dNdS"
    output:
        pairs = pathResults + "phylum_close_species_pairs",
        full = pathResults + "phylum_list_processed_species"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/filter_pairs.py -i {input} -t {threshold} -o {output.pairs} -f {output.full}
        """

rule silixx_phylum:
    input:
        pairs = pathResults + "phylum_close_species_pairs",
        full = pathResults + "phylum_list_processed_species"
    output:
        pathResults + "phylum_clustered_species"
    shell:
        """
        silixx $(wc -l < {input.full}) {input.pairs} > {output}
        """

rule filter_clusters_phylum:
    """
    Removes all species which do not share a cluster with any other
    """
    input:
        pathResults + "phylum_clustered_species"
    output:
        pathResults + "filtered_phylum_clustered_species"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/filter_clusters.py -i {input} -o {output}
        """

checkpoint matrix_cluster_phylum:
    """
    Generate a pseudo-distance matrix using dS for each cluster
    """
    input:
        clust = pathResults + "filtered_phylum_clustered_species",
        ds = pathResults + "seaview_alignment/Alignment_Summaries/phylum_level_full_alignment.dNdS"
    output:
        directory(pathResults + "Phylum_Clustering")
    shell:
        """
        mkdir -p {pathResults}Phylum_Clustering
        python3 {pathScripts}3_ds_computation/python/generate_matrix.py -i {input.clust} -d {input.ds} -l "Phylum" -o {pathResults}Phylum_Clustering/
        """


"""
Make check for all clusters in phylum for getting representatives, and then repeat for phylum
"""

def check_phylum_clusters(wildcards):
    cp_clusters_phylum = checkpoints.matrix_cluster_phylum.get(**wildcards).output[0]
    return expand(pathResults + "Phylum_Clustering/cluster_{clust}_representative_species", clust = glob_wildcards(os.path.join(cp_clusters_phylum, 'cluster_{clust}_matrix.txt')).clust)

rule get_representatives_phylum:
    """
    Get representative for each cluster on phylum step
    """
    input:
        pathResults + "Phylum_Clustering/cluster_{clust}_matrix.txt"
    output:
        pathResults + "Phylum_Clustering/cluster_{clust}_representative_species"
    shell:
        """
        Rscript {pathScripts}3_ds_computation/R/get_representatives.R {input} {output}
        """

rule concatenate_rep_phylum:
    """
    Concatenate all representatives for phylum clusters alongside orphans
    """
    input:
        check_phylum_clusters
    output:
        pathResults + "phylum_full_representative_species"
    shell:
        """
        cat {pathResults}Phylum_Clustering/cluster_*_representative_species {pathResults}list_orphans_phylum > {output}
        """

