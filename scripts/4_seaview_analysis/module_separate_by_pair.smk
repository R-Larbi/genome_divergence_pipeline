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

rule separate_clusters_by_clade:
    input:
        clust = pathResults + "filtered_clustered_species",
        phyla = pathResults + "list_phyla"
    output:
        pathResults + "Clades/{clade}/clustered_species"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/separate_clusters_by_clade.py -f {input.clust} -p {input.phyla} -c {wildcards.clade} -o {output}
        """

rule create_pair_list:
    input:
        clust = get_clades,
        busco = pathBUSCO + "busco_full.fa"
    output:
        touch(temp("pair_lists_done.flag"))
    shell:
        """
        elt=' ' read -a array <<< "{input.clust}";
        for clust in ${{array[@]}};
        do
            python3 {pathScripts}4_seaview_analysis/python/create_pairs.py -b {input.busco} -c ${{clust}} -o {pathResults}Cluster_BUSCO_pairs/
        done
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