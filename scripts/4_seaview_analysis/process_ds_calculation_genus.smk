import json
import glob
import os

configfile: "scripts/4_seaview_analysis/config.json"
cluster  = str(config["cluster"])
part     = config["partition"]
max_part = config["max_part"]


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

with open(pathResources + "filtered_organisms_data") as reader:
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

with open(pathResults + "Cluster_BUSCO_pairs/pairs_cluster_" + cluster, "r") as reader:
    """
    Creates the batch of pairs to pass through seaview
    """
    l = reader.readlines()

    # Getting the range to extract
    fract = float(len(l) / max_part)

    # We reduce the start by one to account for arrays starting from 0
    start = (float(part) - 1.) * float(fract)
    end   = start + fract

    # We round up the start and end
    start = int(start)

    # Sometimes the end float for the last partition has a 0.999... decimal instead of being a whole.
    end   = int(end) + (end % 1 > 0.999)
    
    part_pairs = l[start:end]


PAIRS = []
for line in part_pairs:
    if line.strip() not in PAIRS:
        PAIRS.append(line.strip())

def get_gen_codes(wildcards):
    """
    Takes in the pair and returns the genetic code to use in seaview for each species of the pair
    """

    pair = wildcards.pair

    spec1 = pair.strip().split("-")[0]
    spec2 = pair.strip().split("-")[1]

    tax1 = ""
    tax2 = ""

    code1 = ""
    code2 = ""

    with open(pathResources + "filtered_organisms_data", "r") as reader:
        for line in reader.readlines():
            splitline = line.strip().split("\t")
            if spec1 in splitline[2]:
                tax1 = splitline[1]
            if spec2 in splitline[2]:
                tax2 = splitline[1]
            if spec1 != "" and spec2 != "":
                break
    
    with open(pathResources + "nodes.dmp", "r") as reader:
        for line in reader.readlines():
            splitline = line.strip().split("\t|\t")
            if tax1 in splitline[0]:
                code1 = splitline[6]
            if tax2 in splitline[0]:
                code2 = splitline[6]
            if code1 != "" and code2 != "":
                break
    
    return [code1, code2]

rule all:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/genus_level_full_alignment.dNdS"

rule make_blast_db:
    input:
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathBUSCO + "busco_full.fa.ndb"

    shell:
        """
        makeblastdb -in {input.busco} -dbtype nucl -parse_seqids
        """

rule get_passed_busco:
    """
    Gets the list of species which passed BUSCO with at least one single or multi copy gene
    """
    input:
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathResults + "full_species_list"
    shell:
        """
        grep '>' {input.busco} |awk -F'\t' '{{ print $1 }}' |awk -F'-' '{{ print $2 }}' |uniq > {output}
        """

include: "module_dS_computing_phylum"
include: "module_dS_computing_class"
include: "module_dS_computing_order"
include: "module_dS_computing_family"
include: "module_dS_computing_genus"