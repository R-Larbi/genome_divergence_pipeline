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
        expand(pathBUSCO + "extracted_buscos/{accession}_all_buscos.fa", accession = UNCURATED)

rule busco_genomic:
    """
    Execute BUSCO on unanottated data
    """
    input:
        fna = pathAssemblies + "{accession}/genomic.fna"
    output:
        table = pathBUSCO + "genomic/{accession}/run_eukaryota_odb12/full_table.tsv"
    shell:
        """
        busco -i {input} -f -m genome -l eukaryota_odb12 -c 1 -o data/BUSCO/genomic/{wildcards.accession}
        """

rule concatenate_gffs_genomic:
    """
    Concatenate gffs from genomic BUSCO execution
    """
    input:
        table = pathBUSCO + "genomic/{accession}/run_eukaryota_odb12/full_table.tsv"
    output:
        gff = pathBUSCO + "genomic/{accession}/single_copy_busco_sequences.gff"
    shell:
        """
        find {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/single_copy_busco_sequences/*.gff -type f -print -exec cat {{}} \; > {output}
        """

rule busco_extract_genomic:
    """
    Extract BUSCO sequences from the extracted chr
    """
    input:
        fna = pathAssemblies + "{accession}/genomic.fna",
        gff = pathBUSCO + "genomic/{accession}/single_copy_busco_sequences.gff"
    output:
        touch(pathBUSCO + "{accession}_extraction_done.flag")
    shell:
        """
        mkdir -p {pathBUSCO}extracted_buscos/
        python3 scripts/3_cds_extraction/python/extract_genomic_cds.py -f {input.fna} -g {input.gff} -o {pathBUSCO}extracted_buscos -a {wildcards.accession}
        """

rule busco_concatenate_genomic:
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