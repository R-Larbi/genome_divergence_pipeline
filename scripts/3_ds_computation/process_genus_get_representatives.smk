import json
import glob
import os

configfile: "scripts/3_ds_computation/config.json"
part     = config["partition"]
max_part = config["max_part"]
threshold = config["genus_threshold"]

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

rule all:
    input:
        pathResults + "genus_full_representative_species"

rule concatenate:
    output:
        pathResults + "seaview_alignment/Alignment_Summaries/genus_level_full_alignment.dNdS"
    shell:
        """
        echo -e "Species 1\tSpecies 2\tmedian dN\tmedian dS\tmedian dN/dS\tnb busco genes" > {output}
        for f in {pathResults}seaview_alignment/Alignment_Summaries/genus_level_*-{max_part}_full_alignment.dNdS;
        do
            tail -n+2 $f
        done >> {output}
        """

rule filter_genus:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/genus_level_full_alignment.dNdS"
    output:
        pairs = pathResults + "genus_close_species_pairs",
        full = pathResults + "genus_list_processed_species"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/filter_pairs.py -i {input} -t {threshold} -o {output.pairs} -f {output.full}
        """

rule silixx_genus:
    input:
        pairs = pathResults + "genus_close_species_pairs",
        full = pathResults + "genus_list_processed_species"
    output:
        pathResults + "genus_clustered_species"
    shell:
        """
        silixx $(wc -l < {input.full}) {input.pairs} > {output}
        """

rule filter_clusters_genus:
    """
    Removes all species which do not share a cluster with any other
    """
    input:
        pathResults + "genus_clustered_species"
    output:
        pathResults + "filtered_genus_clustered_species"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/filter_clusters.py -i {input} -o {output}
        """

checkpoint matrix_cluster_genus:
    """
    Generate a pseudo-distance matrix using dS for each cluster
    """
    input:
        clust = pathResults + "filtered_genus_clustered_species",
        ds = pathResults + "seaview_alignment/Alignment_Summaries/genus_level_full_alignment.dNdS"
    output:
        directory(pathResults + "Genus_Clustering")
    shell:
        """
        mkdir -p {pathResults}Genus_Clustering
        python3 {pathScripts}3_ds_computation/python/generate_matrix.py -i {input.clust} -d {input.ds} -l "Genus" -o {pathResults}Genus_Clustering/
        """


"""
Make check for all clusters in genus for getting representatives, and then repeat for genus
"""

def check_genus_clusters(wildcards):
    cp_clusters_genus = checkpoints.matrix_cluster_genus.get(**wildcards).output[0]
    return expand(pathResults + "Genus_Clustering/cluster_{clust}_representative_species", clust = glob_wildcards(os.path.join(cp_clusters_genus, 'cluster_{clust}_matrix.txt')).clust)

rule get_representatives_genus:
    """
    Get representative for each cluster on genus step
    """
    input:
        pathResults + "Genus_Clustering/cluster_{clust}_matrix.txt"
    output:
        pathResults + "Genus_Clustering/cluster_{clust}_representative_species"
    shell:
        """
        Rscript {pathScripts}2_analysis_pipeline/Rscript/get_representatives.R {input} {output}
        """

rule concatenate_rep_genus:
    """
    Concatenate all representatives for genus clusters alongside orphans
    """
    input:
        check_genus_clusters
    output:
        pathResults + "genus_full_representative_species"
    shell:
        """
        cat {pathResults}Genus_Clustering/cluster_*_representative_species {pathResults}list_orphans_genus > {output}
        """

