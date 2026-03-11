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

def all_matrices(wildcards):
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"hashlists/*_hashlist.txt")]
    return expand(pathResults + "{clade}/dist.txt", clade=clades) + expand(pathResults + "{clade}/hr_dist.txt", clade=clades)

rule all:
    """
    Get the distance matrix and its readable counterpart
    """
    input:
        all_matrices

rule get_matrix:
    """
    Execute MIKE to get the distance matrix
    """
    input:
        hashlist = pathMinhash + "hashlists/{clade}_hashlist.txt"
    output:
        matrix = pathResults + "{clade}/dist.txt"
    shell:
        """
        mike dist -l {input} -L {input} -d {pathResults}/{wildcards.clade}
        """

rule readable_matrix:
    """
    Cleans the distance matrix and generates a readable matrix where all accession numbers are replaced by species name
    """
    input:
        matrix = pathResults + "{clade}/dist.txt",
        info   = pathResources + "organisms_data"
    output:
        hr_mat = pathResults + "{clade}/hr_dist.txt"
    shell:
        """
        python3 {pathScripts}2_analysis_pipeline/python/hr_dist.py -d {input.matrix} -i {input.info} -o {output}
        """