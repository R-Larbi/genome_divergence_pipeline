import json
import glob

configfile: "scripts/4_seaview_analysis/config.json"
cluster = str(config["cluster"])

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
    Creates the list of pairs to pass through seaview
    """
    PAIRS = []
    for line in reader.readlines():
        if line.strip() not in PAIRS:
            PAIRS.append(line.strip())

rule all:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/cluster_" + cluster + "_full_alignment_summary.dNdS"

rule separate_by_pair:
    """
    For this rule, we do not specify the inputs.
    If we did, then snakemake would check if the input was updated, and if it was, it would run the rule for EVERY pair.
    We want it to only run the rule for missing pairs, so we only specify the output so it only checks for missing pairs.
    """
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/busco_pairs"
    shell:
        """
        mkdir -p {pathResults}seaview_alignment/Per_BUSCO_Alignments/{wildcards.pair}
        python3 {pathScripts}4_seaview_analysis/python/separate_by_pair.py -p {wildcards.pair} -b {pathResults}Cluster_BUSCO_pairs/busco_cluster_{cluster} -o {output}
        """

"""
rule flag_check:
    input:
        get_clades
    output:
        pathResults + "seaview_alignment/Paired_Alignments/{pair}/busco_pairs"
"""
rule make_blast_db:
    input:
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathBUSCO + "busco_full.fa.ndb"

    shell:
        """
        makeblastdb -in {input.busco} -dbtype nucl -parse_seqids
        """

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

rule seaview:
    input:
        pair  = pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/busco_pairs",
        busco = pathBUSCO + "busco_full.fa",
        db    = pathBUSCO + "busco_full.fa.ndb"
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/per_busco_alignment.dNdS"
    params:
        codes = get_gen_codes
    shell:
        """
        csh scripts/4_seaview_analysis/csh/Aln_dNdS_run_all.csh {input.pair} {input.busco} {wildcards.pair} {params.codes[0]} {params.codes[1]} {output}
        """

rule get_medians:
    input:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/per_busco_alignment.dNdS"
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/full_alignment.dNdS"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/median_dnds.py -i {input} -o {output}
        """

rule summarize:
    input:
        expand(pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/full_alignment.dNdS", pair = PAIRS)
    output:
        pathResults + "seaview_alignment/Alignment_Results/cluster_" + cluster + "_full_alignment_summary.dNdS"
    shell:
        """
        awk 'FNR==1 && NR!=1 {{ next }} {{ print }}' {pathResults}seaview_alignment/Per_BUSCO_Alignments/*/full_alignment.dNdS > {output}
        """