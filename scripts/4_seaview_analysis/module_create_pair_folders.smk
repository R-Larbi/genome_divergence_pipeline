import json
import glob

configfile: "scripts/4_seaview_analysis/config.json"
clade    = config["clade"]
part     = config["part"]
max_part = config["max_part"]

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

with open(pathResults + "Clades/"+clade+"/cluster_pairs", "r") as reader:
    """
    Creates the list of pairs to pass through seaview
    """
    PAIRS = []
    for line in reader.readlines():
        PAIRS.append(line.strip())

rule all:
    input:
        expand(pathResults + "seaview_alignment/"+clade+"/{pair}/busco_pairs", pair=PAIRS)


rule separate_by_pair:
    """
    For this rule, we do not specify the inputs.
    If we did, then snakemake would check if the input was updated, and if it was, it would run the rule for EVERY pair.
    We want it to only run the rule for missing pairs, so we only specify the output so it only checks for missing pairs.
    """
    output:
        pathResults + "seaview_alignment/"+clade+"/{pair}/busco_pairs"
    shell:
        """
        mkdir -p {pathResults}seaview_alignment/{clade}/{wildcards.pair}
        python3 {pathScripts}4_seaview_analysis/python/separate_by_pair.py -p {wildcards.pair} -b {pathResults}Clades/{clade}/busco_pairs -o {pathResults}seaview_alignment/{clade}/{wildcards.pair}/busco_pairs
        """

