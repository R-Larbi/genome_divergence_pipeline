import json
import glob
import os

configfile: "scripts/3_ds_computation/config.json"
part     = config["partition"]
max_part = config["max_part"]
full_part = f"{part}-{max_part}"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

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

def get_family_pairs(wildcards):
    cp_output_family = pathResults + "list_pairs_family"
    FAMILY_PAIRS = []
    with open(cp_output_family, "r") as reader:
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
    for line in part_pairs:
        FAMILY_PAIRS.append(line.strip())
    return expand(pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/full_alignment.dNdS", pair=FAMILY_PAIRS)

rule all:
    input:
        pathResults + "seaview_alignment/Alignment_Summaries/family_level_full_alignment.dNdS"

rule separate_by_pair_family:
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
        python3 {pathScripts}3_ds_computation/python/separate_by_pair.py -p {wildcards.pair} -b {pathResults}busco_pairs_family -o {output}
        """

rule seaview_family:
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
        mkdir -p /tmp/rl_seaview_tmp
        csh scripts/3_ds_computation/csh/Aln_dNdS_run_all.csh {input.pair} {input.busco} {wildcards.pair} {params.codes[0]} {params.codes[1]} {output}
        """

rule get_medians_family:
    input:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/per_busco_alignment.dNdS"
    output:
        pathResults + "seaview_alignment/Per_BUSCO_Alignments/{pair}/full_alignment.dNdS"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/median_dnds.py -i {input} -o {output}
        """

rule summarize_family:
    input:
        get_family_pairs
    output:
        pathResults + "seaview_alignment/Alignment_Summaries/family_level_" + full_part + "_full_alignment.dNdS"
    shell:
        """
        echo -e "Species 1\tSpecies 2\tmedian dN\tmedian dS\tmedian dN/dS\tnb busco genes" > {output}
        elt=' ' read -r -a array <<< "{input}"
        for align in ${{array[@]}};
        do
            if [ $(wc -l < "$align") -gt 1 ]; then tail -n+2 "$align" >> {output}; fi
        done
        """