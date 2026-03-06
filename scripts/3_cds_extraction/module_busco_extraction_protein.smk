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
        expand(pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa", accession = CURATED)

rule clean_isoforms:
    """
    Remove isoforms from a protein fasta
    """
    input:
        faa = pathAssemblies + "{accession}/protein.faa",
        gff = pathAssemblies + "{accession}/genomic.gff"
    output:
        clean = pathAssemblies + "{accession}/clean_protein.faa"
    shell:
        """
        python3 scripts/3_cds_extraction/python/filter_isoforms.py -f {input.faa} -g {input.gff} -o {output}
        """



rule busco_protein:
    """
    Execute BUSCO on anottated data
    """
    input:
        faa = pathAssemblies + "{accession}/clean_protein.faa"
    output:
        table = pathBUSCO + "protein/{accession}/run_eukaryota_odb12/full_table.tsv"
    shell:
        """
        busco -i {input} -f -m protein -l eukaryota_odb12 -c 1 -o data/BUSCO/protein/{wildcards.accession}
        """

rule extract_protein_ids:
    """
    Extract protein IDs for all BUSCO
    """
    input:
        table = pathBUSCO + "protein/{accession}/run_eukaryota_odb12/full_table.tsv"
    output:
        prots = pathBUSCO + "protein/{accession}/extracted_protein_ids"
    shell:
        """
        python3 scripts/3_cds_extraction/python/extract_sequences_protein.py -i {input} -o {output}
        """

rule busco_extract_protein:
    """
    Extract BUSCO sequences based on protein IDs
    """
    input:
        prots = pathBUSCO + "protein/{accession}/extracted_protein_ids",
        gff = pathAssemblies + "{accession}/genomic.gff",
        fna = pathAssemblies + "{accession}/genomic.fna"
    output:
        touch(pathBUSCO + "{accession}_extraction_done.flag")
    shell:
        """
        mkdir -p {pathBUSCO}extracted_buscos/
        python3 scripts/3_cds_extraction/python/extract_protein_cds.py -p {input.prots} -f {input.fna} -g {input.gff} -o {pathBUSCO}extracted_buscos -a {wildcards.accession}
        """

rule busco_concatenate_protein:
    """
    Concatenate all BUSCOs into a single file
    """
    input:
        pathBUSCO + "{accession}_extraction_done.flag"
    output:
        pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa"
    shell:
        """
        cat data/BUSCO/extracted_buscos/{wildcards.accession}_*.fasta > data/BUSCO/extracted_buscos/{wildcards.accession}_all_buscos.fa
        """

include: "module_get_fna.smk"
include: "module_get_faa.smk"
include: "module_get_gff.smk"