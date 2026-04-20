import json

configfile: "scripts/1_fetch_data/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

part = str(config["partition"])

with open(pathResults + "list_species_to_process", "r") as reader:
    PROCESS = [] # List of species to process
    for line in reader.readlines():
        PROCESS.append(line.strip())

with open(pathResources + part + "_filtered_organisms_data", "r") as reader:
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
    input:
        expand(pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa", accession = UNCURATED)

rule busco_genomic:
    """
    Execute BUSCO on unanottated data
    """
    priority: 1
    input:
        fna = pathBank + "{accession}/genomic.fna.gz"
    output:
        e_fna = temp(pathAssemblies + "{accession}/genomic.fna"),
        table = pathBUSCO + "genomic/{accession}/run_eukaryota_odb12/full_table.tsv"
    shell:
        """
        gunzip -c {input} > {output.e_fna}
        busco -i {output.e_fna} -f --offline --download_path ./busco_downloads -m genome -l eukaryota_odb12 -c 1 -o results/BUSCO/genomic/{wildcards.accession}
        """

rule concatenate_gffs_genomic:
    """
    Concatenate gffs from genomic BUSCO execution
    """
    priority: 2
    input:
        table = pathBUSCO + "genomic/{accession}/run_eukaryota_odb12/full_table.tsv"
    output:
        gff = pathBUSCO + "genomic/{accession}/single_copy_busco_sequences.gff"
    shell:
        """
        if ls {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/single_copy_busco_sequences/*.gff; then
            find {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/single_copy_busco_sequences/*.gff -type f -print -exec cat {{}} \; > {output}
        else
            touch {output}
        fi
        rm {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/miniprot_output/ref.mpi
        """

rule busco_extract_genomic:
    """
    Extract BUSCO sequences from the extracted chr
    """
    priority: 3
    input:
        fna = pathAssemblies + "{accession}/genomic.fna",
        gff = pathBUSCO + "genomic/{accession}/single_copy_busco_sequences.gff"
    output:
        pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa"
    shell:
        """
        mkdir -p {pathBUSCO}extracted_buscos/
        python3 scripts/3_cds_extraction/python/extract_genomic_cds.py -f {input.fna} -g {input.gff} -o {pathBUSCO}extracted_buscos -a {wildcards.accession}
        cat {pathBUSCO}extracted_buscos/{wildcards.accession}_*.fasta > {pathBUSCO}extracted_buscos/{wildcards.accession}_all_buscos.fa
        """

"""
rule busco_concatenate_genomic:
    ""
    Concatenate all BUSCOs into a single file
    ""
    input:
        pathBUSCO + "{accession}_extraction_done.flag"
    output:
        pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa"
    shell:
        ""
        cat {pathBUSCO}extracted_buscos/{wildcards.accession}_*.fasta > {pathBUSCO}extracted_buscos/{wildcards.accession}_all_buscos.fa
        ""
"""

#include: "module_get_fna.smk"