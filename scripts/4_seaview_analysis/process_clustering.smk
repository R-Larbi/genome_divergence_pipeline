import json
import glob

configfile: "scripts/4_seaview_analysis/config.json"

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

rule all:
    input:
        pathResults + "total_pair_list"

rule pairs:
    input:
        pathResults + "{clade}/dist.txt"
    output:
        temp(pathResults + "{clade}/species_pairs")
    params:
        t = config["threshold"]
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/cluster_species.py -i {input} -t {params.t} -o {output}
        """

rule silixx:
    input:
        pathResults + "{clade}/species_pairs"
    output:
        temp(pathResults + "{clade}/clustered_species")
    shell:
        """
        silixx "$(wc -l {pathResults}{wildcards.clade}/dist.txt)" {input} > {output}
        """

rule create_pair_list:
    input:
        clust = pathResults + "{clade}/clustered_species",
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathResults + "{clade}/pair_list"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/create_pairs.py -i {input.busco} -c {input.clust} -o {output}
        """

def get_clades_pair_lists(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "{clade}/pair_list", clade=clades)

rule concatenate_pair_lists:
    input:
        get_clades_pair_lists
    output:
        pathResults + "total_pair_list"
    shell:
        """
        cat {pathResults}*/pair_list > {output}
        """