import json

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("../environment_path.json"))

with open("{pathResources}organisms_data") as reader:
    """
    Creates the list of URL that will be used for download
    """
    PATHLIST = []
    ACCESSNB = []
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        if line_data[-1] != 'None': # if there is an existing URL
            ACCESSNB.append(line_data[2])
            PATHLIST.append(f"{line_data[-1]}")

FINAL = ACCESSNB
PATHLIST = dict(zip(FINAL, PATHLIST))

rule all:
    input: 
        expand(pathAssemblies + "{accession}/url_genomic.fna.txt", accession=FINAL)

def GetPath(wildcards):
    return(PATHLIST[wildcards.accession])

rule download_genomic_data:
    params:
        http_path = GetPath
    input:
        pathResources + "organisms_data"
    output:
        pathAssemblies + "{accession}/url_genomic.fna.txt"
    shell:
        """
        echo {pathAssemblies}{wildcards.accession}/{params.http_path}_genomic.fna.gz > {pathAssemblies}{wildcards.accession}/url_genomic.fna.txt
        """