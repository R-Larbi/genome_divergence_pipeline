import json
import glob

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

with open(pathResources + "filtered_organisms_data") as reader:
    """
    Creates the list of accession numbers
    """
    ACCESSNB = []
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        if line_data[-1] != 'None': # if there is an existing URL
            ACCESSNB.append(line_data[2])

FINAL = ACCESSNB

def get_clades(wildcards):
    clades = [Path(x).stem for x in glob.glob(pathResults + f"Clades/*/")]
    return expand(pathResults + "Clades/{clade}/cluster_pairs", clade=clades)

rule all:
    input:
        pathResults + "full_list"

rule create_pair_list:
    input:
        clust = pathResults + "Clades/{clade}/clustered_species",
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathResults + "Clades/{clade}/busco_pairs",
        pathResults + "Clades/{clade}/cluster_pairs"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/create_pairs.py -b {input.busco} -c {input.clust} -o {pathResults}Clades/{wildcards.clade}/
        """

rule full_list:
    input:
        get_clades
    output:
        pathResults + "full_list"
    shell:
        """
        cat {pathResults}Clades/*/cluster_pairs > {pathResults}full_list
        """