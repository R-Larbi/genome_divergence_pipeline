import json

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

with open(pathResources + "filtered_organisms_data", "r") as reader:
    """
    Get the list of curated ones
    """
    UNCURATED = [] # Assemblies without annotation and protein sequence
    CURATED = [] # Assemblies with annotation and protein sequence
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        acc_trunc = line_data[2].strip().split(".")[0] # Get truncated accession number for comparison with PROCESS list
        if line_data[-1] != 'None' and line_data[3] == 'True' and acc_trunc in PROCESS: # if there is an existing URL and genome is curated
                CURATED.append(line_data[2])
        elif line_data[-1] != 'None' and acc_trunc in PROCESS:
                UNCURATED.append(line_data[2])
if CURATED == []:
        ACCESSNB = UNCURATED
elif UNCURATED == []:
        ACCESSNB = CURATED
else:
        ACCESSNB = UNCURATED + CURATED

rule all:
    """
    Get extracted sequences for BUSCOs
    """
    input:
        pair_list = pathBUSCO + "busco_full.fa"


rule concatenate_all_buscos:
    """
    Concatenate BUSCO files of all species
    """
    input:
        busco = expand(pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa", accession=ACCESSNB)
    output:
        busco_cat = pathBUSCO + "busco_full.fa"
    shell:
        """
        cat {pathBUSCO}extracted_buscos/*_all_buscos.fa > {pathBUSCO}busco_full.fa
        """