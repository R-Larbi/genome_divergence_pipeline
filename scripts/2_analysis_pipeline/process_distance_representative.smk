import json
import glob
import os

configfile: "scripts/2_analysis_pipeline/config.json"
configfile: "scripts/1_fetch_data/config.json"

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
def get_pairs(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "Clades/{clade}/representative_passing_pairs", clade=clades)

rule all:
    input:
        pathResults + "pairs_step1"

"""
def get_clades_representatives(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "Clades/{clade}/representative", clade=clades)

rule concatenate_representatives:
    input:
        get_clades_representatives
    output:
        pathResults + "list_representatives"
    shell:
        ""
        cat {pathResults}Clades/*/representative > {output}
        rm {pathResults}Clades/*/representative
        ""
"""

rule write_comparison_list:
    """
    Writes a list of species for which to compute distance with for every representative species
    """
    input:
        rep = pathResults + "Clades/{clade}/representative",
        phy = pathResults + "list_phyla"
    output:
        pathResults + "Clades/{clade}/comparison_list"
    shell:
        """
        python3 {pathScripts}2_analysis_pipeline/python/create_comparison_list.py -r {input.rep} -p {input.phy} -o {output} -f {pathResults}Clades/{wildcards.clade}/phylum.flag
        """

"""
rule comparison_per_clade:
    ""
    Runs a matrix for each pairing of clade representative with another species, then writes it as a pair if under threshold 
    ""
    input:
        rep = pathResults + "Clades/{clade}/representative",
        comp = pathResults + "Clades/{clade}/comparison_list"
    output:
        pathResults + "Clades/{clade}/representative_passing_pairs"
    shell:
        ""
        touch {output}
        mkdir {pathResults}Clades/{wildcards.clade}/tmp_comp
        while read c; do
            echo {pathMinhash}kmc_"$(cat {input.rep})".minhash.jac\n{pathMinhash}kmc_"$c".minhash.jac > tmp_pair_"$c".txt
            mike dist -l tmp_pair_"$c".txt -L tmp_pair_"$c".txt -d {pathResults}Clades/{wildcards.clade}/tmp_comp
            python3 {pathScripts}2_analysis_pipeline/python/threshold_check.py -d {pathResults}Clades/{wildcards.clade}/tmp_comp/dist.txt -p {output}
            rm {pathResults}Clades/{wildcards.clade}/tmp_comp/dist.txt
        done < {input.comp}
        rm -r {pathResults}Clades/{wildcards.clade}/tmp_comp
        ""
"""

rule comparison_per_clade:
    """
    Runs a matrix for each pairing of clade representative with another species, then writes it as a pair if under threshold 
    """
    input:
        rep = pathResults + "Clades/{clade}/representative",
        comp = pathResults + "Clades/{clade}/comparison_list"
    output:
        pathResults + "Clades/{clade}/representative_passing_pairs"
    params:
        t = config["threshold"]
    shell:
        """
        mkdir {pathResults}Clades/{wildcards.clade}/tmp_comp
        echo {pathMinhash}kmc_"$(cat {input.rep})".minhash.jac > {pathResults}Clades/{wildcards.clade}/tmp_comp/tmp_hashlist_1
        while read c; do
            echo {pathMinhash}kmc_"$c".minhash.jac
        done < {input.comp} > {pathResults}Clades/{wildcards.clade}/tmp_comp/tmp_hashlist_2
        if ! test -f {pathResults}Clades/{wildcards.clade}/phylum.flag; then
            mike dist -l {pathResults}Clades/{wildcards.clade}/tmp_comp/tmp_hashlist_1 -L {pathResults}Clades/{wildcards.clade}/tmp_comp/tmp_hashlist_2 -d {pathResults}Clades/{wildcards.clade}/tmp_comp
            python3 {pathScripts}2_analysis_pipeline/python/threshold_check.py -d {pathResults}Clades/{wildcards.clade}/tmp_comp/dist.txt -p {output} -t {params.t}
        else
            rm {pathResults}Clades/{wildcards.clade}/phylum.flag
            touch {output}
        fi
        rm -r {pathResults}Clades/{wildcards.clade}/tmp_comp
        """

rule concatenate_lists_pairs:
    """
    Concatenates all found pairs into a single file
    """
    input:
        get_pairs
    output:
        pathResults + "pairs_step1"
    shell:
        """
        cat {pathResults}Clades/*/representative_passing_pairs > {output}
        sed -i '/^$/d' {output}
        rm {pathResults}Clades/*/representative_passing_pairs
        """