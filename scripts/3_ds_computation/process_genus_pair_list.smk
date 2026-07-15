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
        fam = pathResults + "list_pairs_genus",
        singles = pathResults + "list_orphans_genus",
        busco = pathResults + "busco_pairs_genus"

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
        busco = pathBUSCO + "busco_full.fa",
        db = pathBUSCO + "busco_full.fa.ndb"
    output:
        pathResults + "full_species_list"
    shell:
        """
        grep '>' {input.busco} |awk -F'\t' '{{ print $1 }}' |awk -F'-' '{{ print $2 }}' |uniq > {output}
        """

rule get_genus_list:
    input:
        tax_data = pathResources + "ncbi_dataset_eukaryota.taxonomy",
        species = pathResults + "full_species_list"
    output:
        fam = pathResults + "list_pairs_genus",
        singles = pathResults + "list_orphans_genus"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/generate_pairs.py -i {input.species} -t {input.tax_data} -l "Genus" -o {output.fam} -s {output.singles}
        """

rule create_pair_list_genus:
    input:
        pairs = pathResults + "list_pairs_genus",
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathResults + "busco_pairs_genus"
    shell:
        """
        python3 {pathScripts}3_ds_computation/python/create_busco_pairs.py -i {input.pairs} -b {input.busco} -o {pathResults}busco_pairs_genus
        """