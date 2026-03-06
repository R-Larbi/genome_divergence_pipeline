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
    input:
        pathBUSCO + "genomic/done.flag",
        pathBUSCO + "protein/done.flag"

rule separate_genomic:
    output:
        temp(pathBUSCO + "genomic/done.flag")
    shell:
        """
        mkdir -p {pathBUSCO}genomic
        elt=' ' read -a array <<< "{UNCURATED}"
        for acc in ${{array[@]}};
        do
            mkdir -p {pathBUSCO}genomic/"$acc"
        done
        touch {pathBUSCO}genomic/done.flag
        """

rule separate_protein:
    output:
        temp(pathBUSCO + "protein/done.flag")
    shell:
        """
        mkdir -p {pathBUSCO}protein
        elt=' ' read -a array <<< "{CURATED}"
        for acc in ${{array[@]}};
        do
            mkdir -p {pathBUSCO}protein/"$acc"
        done
        touch {pathBUSCO}protein/done.flag
        """