import json
import glob

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

with open(pathResults + "list_species_to_process", "r") as reader:
    PROCESS = [] # List of species to process
    for line in reader.readlines():
        PROCESS.append(line.strip())

with open(pathResources + "organisms_data") as reader:
    """
    Creates the list of accession numbers
    """
    ACCESSNB = []
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        acc_trunc = line_data[2].strip().split(".")[0] # Get truncated accession number for comparison with PROCESS list
        if line_data[-1] != 'None' and acc_trunc in PROCESS: # if there is an existing URL
            ACCESSNB.append(line_data[2])

FINAL = ACCESSNB

"""
def get_clades(wildcards):
    clades = [Path(x).stem for x in glob.glob(pathResults + f"Clades/*/")]
    return expand(pathResults + "Clades/{clade}/cluster_pairs", clade=clades)
"""

def get_clades(wildcards):
    clades = [Path(x).stem for x in glob.glob(pathResults + f"Clades/*/")]
    return expand(pathResults + "Clades/{clade}/clustered_species", clade=clades)

rule all:
    input:
        pathResults + "full_list"

checkpoint get_genus_list:
    input:
        tax_data = pathResources + "ncbi_dataset_eukaryota.taxonomy"
    output:
        pathResults + "list_pairs_genus"
    shell:
        """
        python3 {pathScripts}number_step/python/generate_pairs.py -t {input.tax_data} -c 'Genus' -o {output}
        """

def get_genus_pairs(wildcards):
    cp_output_genus = checkpoints.get_genus_list.get(**wildcards).output[0]
    GENUS_PAIRS = []
    with open(cp_output_genus, "r") as reader:
        for line in reader.readlines():
            GENUS_PAIRS.append(line.strip())
    return expand(pathResults + "seaview_alignment/Per_BUSCO_Alignment/{pair}/full_alignment.dNdS", pair=GENUS_PAIRS)

rule create_pair_list:
    input:
        pairs = pathResults + "list_pairs_genus",
        busco = pathBUSCO + "busco_full.fa"
    output:
        touch(temp("pair_lists_done.flag"))
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/create_pairs.py -i {input.pairs} -b {input.busco} -o {pathResults}Cluster_BUSCO_pairs/
        """

rule full_list:
    input:
        "pair_lists_done.flag"
    output:
        pathResults + "full_list"
    shell:
        """
        cat {pathResults}Cluster_BUSCO_pairs/pairs_cluster_* > {pathResults}full_list
        """