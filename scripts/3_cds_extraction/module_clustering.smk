import json
import glob

configfile: "scripts/3_cds_extraction/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

with open(pathResources + "organisms_data") as reader:
    """
    Creates the list of accession numbers
    """
    ACCESSNB = []
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        if line_data[-1] != 'None': # if there is an existing URL
            ACCESSNB.append(line_data[2])

FINAL = ACCESSNB

def get_clades_dist(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "Clades/{clade}/dist.txt", clade=clades)

def get_clades_clusters(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "Clades/{clade}/filtered_clustered_species", clade=clades)

def get_clades_pair_lists(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "Clades/{clade}/species_pairs", clade=clades)

rule all:
    input:
        pathResources + "filtered_organisms_data"

rule pairs:
    input:
        pathResults + "Clades/{clade}/dist.txt"
    output:
        temp(pathResults + "Clades/{clade}/species_pairs")
    params:
        t = config["threshold"]
    shell:
        """
        python3 {pathScripts}3_cds_extraction/python/cluster_species.py -i {input} -t {params.t} -o {output}
        """

rule concatenate_pair_lists:
    input:
        get_clades_pair_lists
    output:
        pathResults + "total_pair_list"
    shell:
        """
        cat {pathResults}Clades/*/species_pairs > {pathResults}pairs_step2
        cat {pathResults}pairs_step1 {pathResults}pairs_step2 > {output}
        """

rule silixx:
    input:
        dist = pathResults + "Clades/{clade}/dist.txt",
        pair = pathResults + "Clades/{clade}/species_pairs"
    output:
        pathResults + "Clades/{clade}/clustered_species"
    shell:
        """
        silixx $(($(wc -l < {input.dist})-1)) {input.pair} > {output}
        """

rule silixx_full:
    input:
        dist = get_clades_dist,
        pair = pathResults + "total_pair_list"
    output:
        pathResults + "full_clustered_species"
    shell:
        """
        for file in {pathResults}Clades/*/dist.txt;
        do
            tail -n+2 "$file"
        done > {pathResults}full_dist.txt
        silixx $(($(wc -l < {pathResults}full_dist.txt))) {input.pair} > {output}
        rm {pathResults}full_dist.txt
        """


rule filter_clusters:
    """
    Removes all species which do not share a cluster with any other
    """
    input:
        pathResults + "full_clustered_species"
    output:
        pathResults + "filtered_clustered_species"
    shell:
        """
        python3 {pathScripts}3_cds_extraction/python/filter_clusters.py -i {input} -o {output}
        """

rule filter_org_data:
    input:
        clust = pathResults + "filtered_clustered_species",
        org_data = pathResources + "organisms_data"
    output:
        filtered = pathResources + "filtered_organisms_data",
        spec_list = pathResults + "list_species_to_process"
    shell:
        """
        awk -F '\t' '{{print $2}}' {input.clust} > {output.spec_list}
        python3 scripts/3_cds_extraction/python/filter_org_data.py -i {input.clust} -d {input.org_data} -o {output.filtered}
        """