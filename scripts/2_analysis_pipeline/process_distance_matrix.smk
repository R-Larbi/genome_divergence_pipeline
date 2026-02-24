import json

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


rule all:
    """
    Get the distance matrix and its readable counterpart
    """

    input:
        matrix = pathResults + "dist.txt",
        hr_mat = pathResults + "hr_dist.txt"


rule write_hashlist:
    """
    Write the list of sketched files for MIKE processing
    """
    input:
        expand(pathMinhash + "kmc_{accession}.minhash.jac", accession=ACCESSNB)
    output:
        hashlist = pathMinhash + "hashlist.txt"
    shell:
        """
        python3 {pathScripts}2_analysis_pipeline/python/write_hashlist.py -i {pathMinhash} -o {output}
        """

rule get_matrix:
    """
    Execute MIKE to get the distance matrix
    """
    input:
        hashlist = pathMinhash + "hashlist.txt"
    output:
        matrix = pathResults + "dist.txt"
    shell:
        """
        ~/MIKE/src/mike dist -l {input} -L {input} -d {pathResults}
        """

rule readable_matrix:
    """
    Cleans the distance matrix and generates a readable matrix where all accession numbers are replaced by species name
    """
    input:
        matrix = pathResults + "dist.txt",
        info   = pathResources + "organisms_data"
    output:
        hr_mat = pathResults + "hr_dist.txt"
    shell:
        """
        python3 {pathScripts}2_analysis_pipeline/python/hr_dist.py -d {input.matrix} -i {input.info} -o {output}
        """