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

def get_clades_clusters(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "{clade}/clustered_species", clade=clades)

def get_pairs(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "{clade}/species_pairs", clade=clades)

rule all:
    input:
        pathResources + "filtered_organisms_data"

rule pairs:
    input:
        pathResults + "{clade}/dist.txt"
    output:
        temp(pathResults + "{clade}/species_pairs")
    params:
        t = config["threshold"]
    shell:
        """
        python3 {pathScripts}3_cds_extraction/python/cluster_species.py -i {input} -t {params.t} -o {output}
        """
"""
rule silixx:
    input:
        dist = pathResults + "{clade}/dist.txt",
        pair = pathResults + "{clade}/species_pairs"
    output:
        pathResults + "{clade}/clustered_species"
    shell:
        ""
        {pathScripts}3_cds_extraction/bash/run_silixx_all_clades.sh {input.dist} {input.pair} {output}
        ""
"""
rule filter_org_data:
    input:
        get_clades_clusters,
        org_data = pathResources + "organisms_data"
    output:
        pathResources + "filtered_organisms_data"
    shell:
        """
        for i in {pathResults}*/clustered_species; do cat $i; done >> {pathResults}cat_clustered_species
        python3 scripts/3_cds_extraction/python/filter_org_data.py -i {pathResults}cat_clustered_species -d {input.org_data} -o {output}
        rm {pathResults}cat_clustered_species
        """
