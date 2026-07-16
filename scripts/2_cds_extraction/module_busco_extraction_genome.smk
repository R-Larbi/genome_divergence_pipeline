import json

configfile: "scripts/2_cds_extraction/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

part = int(config["partition"])
max_part = int(config["max_part"])

with open(pathResults + "list_species_to_process", "r") as reader:
    PROCESS = [] # List of species to process
    for line in reader.readlines():
        PROCESS.append(line.strip())

with open(pathResources + "organisms_data", "r") as reader:
    """
    Get the list of curated ones
    """
    l = reader.readlines()[1:]

    # Getting the range to extract
    fract = float(len(l) / max_part)

    # We reduce the start by one to account for arrays starting from 0
    start = (float(part) - 1.) * float(fract)
    end   = start + fract

    # We round up the start and end
    start = int(start)

    # Sometimes the end float for the last partition has a 0.999... decimal instead of being a whole.
    end   = int(end) + (end % 1 > 0.999)
        
    part_org_data = l[start:end]


UNCURATED = [] # Assemblies without annotation and protein sequence
CURATED = [] # Assemblies with annotation and protein sequence
for line in part_org_data:
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
    Checks if single or multi-copy BUSCO genes were found, and if so concatenates them.
    If none were found, touch an empty file.
    Also deletes sizeable log and temp files.
    """
    priority: 2
    input:
        table = pathBUSCO + "genomic/{accession}/run_eukaryota_odb12/full_table.tsv"
    output:
        gff = pathBUSCO + "genomic/{accession}/single_copy_busco_sequences.gff"
    shell:
        """
        if [ $(ls '{pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/single_copy_busco_sequences/*.gff' 2> /dev/null |wc -l) -gt 0 ]; then
            find {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/single_copy_busco_sequences/*.gff -type f -print -exec cat {{}} \; > {output}
        fi
        if [ $(ls '{pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/multi_copy_busco_sequences/*.gff' 2> /dev/null |wc -l) -gt 0; then
            find {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/multi_copy_busco_sequences/*.gff -type f -print -exec cat {{}} \; >> {output}
            for p in $(ls {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/multi_copy_busco_sequences/*.gff);
            do
                echo $(basename $p) >> {pathBUSCO}genomic/{wildcards.accession}/multi_copy_buscos
            done
        fi
        if [ $(ls '{pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/single_copy_busco_sequences/*.gff' 2> /dev/null) -gt 0 ] || [ $(ls '{pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/busco_sequences/multi_copy_busco_sequences/*.gff' 2> /dev/null) -gt 0 ]; then
            echo "GFFs concatenated."
        else
            echo "No BUSCO found for {wildcards.accession}"
            touch {output}
        fi
        if [ -f '{pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/miniprot_output/ref.mpi' ]; then
            rm {pathBUSCO}genomic/{wildcards.accession}/run_eukaryota_odb12/miniprot_output/ref.mpi
        fi
        if [ -f '{pathBUSCO}genomic/{wildcards.accession}/logs/miniprot_align_eukaryota_odb12_out.log' ]; then
            rm {pathBUSCO}genomic/{wildcards.accession}/logs/miniprot_align_eukaryota_odb12_out.log
        fi
        if [ -d '{pathBUSCO}genomic/{wildcards.accession}/tmp/' ]; then
            rm -r {pathBUSCO}genomic/{wildcards.accession}/tmp/
        fi
        """

rule busco_extract_genomic:
    """
    Extract BUSCO sequences from the genomic fasta
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
        python3 scripts/2_cds_extraction/python/extract_genomic_cds.py -f {input.fna} -g {input.gff} -o {pathBUSCO}extracted_buscos -a {wildcards.accession}
        if compgen -G '{pathBUSCO}extracted_buscos/{wildcards.accession}_*.fasta' > /dev/null; then
            cat {pathBUSCO}extracted_buscos/{wildcards.accession}_*.fasta > {output}
        else
            touch {output}
        fi
        """