import json

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

with open("data/resources/organisms_data") as reader:
    """
    Get the list of curated ones
    """
    UNCURATED = [] # Assemblies without annotation and protein sequence
    CURATED = [] # Assemblies with annotation and protein sequence
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        if line_data[-1] != 'None' and line_data[3] == 'True': # if there is an existing URL and genome is curated
                CURATED.append(line_data[2])
        elif line_data[-1] != 'None':
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
        rm {pathBUSCO}*_extraction_done.flag
        """