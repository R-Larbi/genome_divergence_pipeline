import json
import glob
import os

configfile: "scripts/3_ds_computation/config.json"
part     = config["partition"]
max_part = config["max_part"]
threshold = config["order_threshold"]

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

rule all:
    input:
        pathResults + "order_full_representative_species"

rule concatenate:
    output:
        pathResults + "seaview_alignment/Alignment_Summaries/order_level_full_alignment.dNdS"
    shell:
        """
        echo -e "Species 1\tSpecies 2\tmedian dN\tmedian dS\tmedian dN/dS\tnb busco genes" > {output}
        for f in {pathResults}seaview_alignment/Alignment_Summaries/order_level_*-*_full_alignment.dNdS;
        do
            tail -n+2 $f
        done >> {output}
        """

rule filter_order:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/order_level_full_alignment.dNdS"
    output:
        pairs = pathResults + "order_close_species_pairs",
        full = pathResults + "order_list_processed_species"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/filter_pairs.py -i {input} -t {threshold} -o {output.pairs} -f {output.full}
        """

rule silixx_order:
    input:
        pairs = pathResults + "order_close_species_pairs",
        full = pathResults + "order_list_processed_species"
    output:
        pathResults + "order_clustered_species"
    shell:
        """
        silixx $(wc -l < {input.full}) {input.pairs} > {output}
        """

rule filter_clusters_order:
    """
    Removes all species which do not share a cluster with any other
    """
    input:
        pathResults + "order_clustered_species"
    output:
        pathResults + "filtered_order_clustered_species"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/filter_clusters.py -i {input} -o {output}
        """

checkpoint matrix_cluster_order:
    """
    Generate a pseudo-distance matrix using dS for each cluster
    """
    input:
        clust = pathResults + "filtered_order_clustered_species",
        ds = pathResults + "seaview_alignment/Alignment_Summaries/order_level_full_alignment.dNdS"
    output:
        directory(pathResults + "Order_Clustering")
    shell:
        """
        mkdir -p {pathResults}Order_Clustering
        python3 {pathScripts}3_ds_computation/python/generate_matrix.py -i {input.clust} -d {input.ds} -l "Order" -o {pathResults}Order_Clustering/
        """


"""
Make check for all clusters in order for getting representatives, and then repeat for order
"""

def check_order_clusters(wildcards):
    cp_clusters_order = checkpoints.matrix_cluster_order.get(**wildcards).output[0]
    return expand(pathResults + "Order_Clustering/cluster_{clust}_representative_species", clust = glob_wildcards(os.path.join(cp_clusters_order, 'cluster_{clust}_matrix.txt')).clust)

rule get_representatives_order:
    """
    Get representative for each cluster on order step
    """
    input:
        pathResults + "Order_Clustering/cluster_{clust}_matrix.txt"
    output:
        pathResults + "Order_Clustering/cluster_{clust}_representative_species"
    shell:
        """
        Rscript {pathScripts}3_ds_computation/R/get_representatives.R {input} {output}
        """

rule concatenate_rep_order:
    """
    Concatenate all representatives for order clusters alongside orphans
    """
    input:
        check_order_clusters
    output:
        pathResults + "order_full_representative_species"
    shell:
        """
        cat {pathResults}Order_Clustering/cluster_*_representative_species {pathResults}list_orphans_order > {output}
        """

