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
        line_proc = line.strip().split(".")[0]
        PROCESS.append(line_proc)

with open(pathResources + "organisms_data", "r") as reader:
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
        expand(pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa", accession = CURATED)

rule clean_isoforms:
    """
    Remove isoforms from a protein fasta
    """
    priority: 1
    input:
        faa = pathAssemblies + "{accession}/protein.faa",
        gff = pathAssemblies + "{accession}/genomic.gff"
    output:
        clean = pathAssemblies + "{accession}/clean_protein.faa"
    shell:
        """
        python3 scripts/2_cds_extraction/python/filter_isoforms.py -f {input.faa} -g {input.gff} -o {output}
        """



rule busco_protein:
    """
    Execute BUSCO on anottated data
    """
    priority: 2
    input:
        faa = pathAssemblies + "{accession}/clean_protein.faa"
    output:
        table = pathBUSCO + "protein/{accession}/run_eukaryota_odb12/full_table.tsv"
    shell:
        """
        busco -i {input} -f --offline --download_path ./busco_downloads -m protein -l eukaryota_odb12 -c 1 -o results/BUSCO/protein/{wildcards.accession}
        """

rule extract_protein_ids:
    """
    Extract protein IDs for all BUSCO
    """
    priority: 3
    input:
        table = pathBUSCO + "protein/{accession}/run_eukaryota_odb12/full_table.tsv"
    output:
        prots = pathBUSCO + "protein/{accession}/extracted_protein_ids"
    shell:
        """
        python3 scripts/2_cds_extraction/python/extract_sequences_protein.py -i {input} -o {output}
        """

rule busco_extract_protein:
    """
    Extract BUSCO sequences based on protein IDs
    """
    priority: 4
    input:
        prots = pathBUSCO + "protein/{accession}/extracted_protein_ids",
        gff = pathAssemblies + "{accession}/genomic.gff",
        fna = pathBank + "{accession}/genomic.fna.gz"
    output:
        pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa"
    shell:
        """
        mkdir -p {pathBUSCO}extracted_buscos/
        gunzip -c {input.fna} > {pathAssemblies}{wildcards.accession}/genomic.fna
        python3 scripts/2_cds_extraction/python/extract_protein_cds.py -p {input.prots} -f {pathAssemblies}{wildcards.accession}/genomic.fna -g {input.gff} -o {pathBUSCO}extracted_buscos -a {wildcards.accession}
        rm {pathAssemblies}{wildcards.accession}/genomic.fna
        cat {pathBUSCO}extracted_buscos/{wildcards.accession}_*.fasta > {pathBUSCO}extracted_buscos/{wildcards.accession}_all_buscos.fa
        """

include: "module_get_faa.smk"
include: "module_get_gff.smk"