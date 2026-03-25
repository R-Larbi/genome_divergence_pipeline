import json
import glob

configfile: "scripts/4_seaview_analysis/config.json"
clade = config["clade"]

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
        pathResults + clade + "_full_alignment_summary.dNdS"

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

rule seaview:
    input:
        pair  = pathResults + "seaview_alignment/"+clade+"/{pair}/busco_pairs",
        busco = pathBUSCO + "busco_full.fa",
        db    = pathBUSCO + "busco_full.fa.ndb"
    output:
        pathResults + "seaview_alignment/"+clade+"/Alignment_Results/{pair}/per_busco_alingment.dNdS"
    shell:
        """
        csh scripts/4_seaview_analysis/csh/Aln_dNdS_run_all.csh {input.pair} {input.busco} {wildcards.pair} 1 {output}
        """

rule get_medians:
    input:
        pathResults + "seaview_alignment/"+clade+"/Alignment_Results/{pair}/per_busco_alingment.dNdS"
    output:
        pathResults + "seaview_alignment/"+clade+"/Alignment_Results/{pair}/full_alignment.dNdS"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/median_dnds.py -i {input} -o {output}
        """

rule summarize:
    input:
        expand(pathResults + "seaview_alignment/"+clade+"/Alignment_Results/{pair}/full_alignment.dNdS", pair = PAIRS)
    output:
        pathResults + clade + "_full_alignment_summary.dNdS"
    shell:
        """
        awk 'FNR==1 && NR!=1 {{ next }} {{ print }}' {pathResults}seaview_alignment/{clade}/Alignment_Results/*/full_alignment.dNdS > {output}
        """