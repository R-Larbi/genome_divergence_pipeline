import json

configfile: "scripts/1_fetch_data/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

part = str(config["partition"])
temp_path = "/home/larbi/virtual_machine_assemblies/assemblies/"

with open("/home/larbi/remaining_organisms_data") as reader:
    """
    Creates the list of URL that will be used for download
    """
    PATHLIST = []
    ACCESSNB = []
    CUR_LIST = []
    CURATED = [] # Assemblies with annotation and protein sequence
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        if line_data[-1] != 'None': # if there is an existing URL
            ACCESSNB.append(line_data[2])
            PATHLIST.append(f"{line_data[-1]}")
            if line_data[3] == 'True': # if genome is curated
                CUR_LIST.append(f"{line_data[-1]}")
                CURATED.append(line_data[2])
                print(line_data[2], line_data[3])

FINAL = ACCESSNB
PATHLIST = dict(zip(FINAL, PATHLIST))

rule all:
    input: 
        expand(temp_path + "{accession}/url_protein.faa.txt", accession=CURATED),
        expand(temp_path + "{accession}/url_genomic.fna.txt", accession=FINAL),
        expand(temp_path + "{accession}/url_genomic.gff.txt", accession=CURATED)

def GetPath(wildcards):
    return(PATHLIST[wildcards.accession])

rule download_protein_data:
    params:
        http_path = GetPath
    input:
        "/home/larbi/remaining_organisms_data"
    output:
        temp_path + "{accession}/url_protein.faa.txt"
    shell:
        """
        echo {params.http_path}_protein.faa.gz > {temp_path}{wildcards.accession}/url_protein.faa.txt
        """

rule download_genomic_data:
    params:
        http_path = GetPath
    input:
        "/home/larbi/remaining_organisms_data"
    output:
        temp_path + "{accession}/url_genomic.fna.txt"
    shell:
        """
        echo {params.http_path}_genomic.fna.gz > {temp_path}{wildcards.accession}/url_genomic.fna.txt
        """

rule download_annotation_data:
    params:
        http_path = GetPath
    input:
        "/home/larbi/remaining_organisms_data"
    output:
        temp_path + "{accession}/url_genomic.gff.txt"
    shell:
        """
        echo {params.http_path}_genomic.gff.gz > {temp_path}{wildcards.accession}/url_genomic.gff.txt
        """