import json
import glob
import os

configfile: "scripts/3_ds_computation/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

rule all:
    input:
        fam = pathResults + "list_pairs_class",
        singles = pathResults + "list_orphans_class",
        busco = pathResults + "busco_pairs_class"

rule get_class_list:
    input:
        tax_data = pathResources + "ncbi_dataset_eukaryota.taxonomy",
        species = pathResults + "order_full_representative_species"
    output:
        fam = pathResults + "list_pairs_class",
        singles = pathResults + "list_orphans_class"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/generate_pairs.py -i {input.species} -t {input.tax_data} -l "Class" -o {output.fam} -s {output.singles}
        """

rule create_pair_list_class:
    input:
        pairs = pathResults + "list_pairs_class",
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathResults + "busco_pairs_class"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/create_busco_pairs.py -i {input.pairs} -b {input.busco} -o {pathResults}busco_pairs_class
        """