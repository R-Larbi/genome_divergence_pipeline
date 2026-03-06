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

def all_clades(wildcards):
    mat_out = checkpoints.write_hashlist.get(**wildcards).output[0]
    clades = [Path(x).stem.split("_")[0] for x in glob.glob(pathMinhash + f"*_hashlist.txt")]
    return expand(pathMinhash + "hashlists/{clade}_hashlist.txt", clade=clades)

rule all:
    """
    Get the lists of minhashes
    """

    input:
        hashlists = all_clades

rule list_accessions:
    """
    Put all the accession numbers of processed minhashes into a text file
    """
    input:
        expand(pathMinhash + "kmc_{accession}.minhash.jac", accession=ACCESSNB)
    output:
        temp(pathMinhash + "accession_list.txt")
    shell:
        """
        ls -p {pathMinhash} | grep -v / > {output}
        """
    
checkpoint write_hashlist:
    """
    Write the list of sketched files for MIKE processing
    """
    input:
        acc_list = pathMinhash + "accession_list.txt",
        tax = pathResources + "ncbi_dataset_eukaryota_reduced.taxonomy"
    output:
        hashlist = directory(pathMinhash + "hashlists")
    shell:
        """
        mkdir -p data/minhash/hashlists
        Rscript {pathScripts}2_analysis_pipeline/Rscript/get_clusters.R {input.tax} {input.acc_list}
        """