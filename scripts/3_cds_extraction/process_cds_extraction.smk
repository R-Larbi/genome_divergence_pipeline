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
    """
    Get extracted sequences for BUSCOs
    """
    input:
        align = "results/aligned_buscos.KaKs"


rule clean_isoforms:
    """
    Remove isoforms from a protein fasta
    """
    input:
        faa = expand("data/assemblies/{accession}/protein.faa", accession=CURATED),
        gff = expand("data/assemblies/{accession}/genomic.gff", accession=CURATED)
    output:
        clean = expand("data/assemblies/{accession}/clean_protein.faa", accession=CURATED)
    shell:
        """
        elt=' ' read -r -a array <<< "{CURATED}"
        for acc in ${{array[@]}};
        do
            python3 scripts/3_cds_extraction/python/filter_isoforms.py -f data/assemblies/"$acc"/protein.faa -g data/assemblies/"$acc"/genomic.gff -o data/assemblies/"$acc"/clean_protein.faa
        done
        """

rule busco_genomic:
    """
    Execute BUSCO on unanottated data
    """
    input:
        fna = expand("data/assemblies/{accession}/genomic.fna.gz", accession=UNCURATED)
    output:
        table = expand("data/BUSCO/{accession}/run_eukaryota_odb12/full_table.tsv", accession=UNCURATED)
    shell:
        """
        elt=' ' read -r -a array <<< "{UNCURATED}"
        for acc in ${{array[@]}};
        do
            busco -i data/assemblies/"$acc"/genomic.fna.gz -f -m genome -l eukaryota_odb12 -c 2 -o data/BUSCO/"$acc"
        done
        """

rule busco_protein:
    """
    Execute BUSCO on anottated data
    """
    input:
        faa = expand("data/assemblies/{accession}/protein.faa", accession=CURATED)
    output:
        table = expand("data/BUSCO/{accession}/run_eukaryota_odb12/full_table.tsv", accession=CURATED)
    shell:
        """
        elt=' ' read -r -a array <<< "{CURATED}"
        for acc in ${{array[@]}};
        do
            busco -i data/assemblies/"$acc"/protein.faa -f -m protein -l eukaryota_odb12 -c 2 -o data/BUSCO/"$acc"
        done
        """


############ GENOMIC BUSCO ###############

rule concatenate_gffs_genomic:
    """
    Concatenate gffs from genomic BUSCO execution
    """
    input:
        table = expand("data/BUSCO/{accession}/run_eukaryota_odb12/full_table.tsv", accession=UNCURATED)
    output:
        gff = expand("data/BUSCO/{accession}/single_copy_busco_sequences.gff", accession=UNCURATED)
    shell:
        """
        elt=' ' read -r -a array <<< "{UNCURATED}"
        for acc in ${{array[@]}};
        do
            find data/BUSCO/"$acc"/run_eukaryota_odb12/busco_sequences/single_copy_busco_sequences/*.gff -type f -print -exec cat {} \; > data/BUSCO/"$acc"/single_copy_busco_sequences.gff
        done
        """

checkpoint busco_extract_genomic:
    """
    Extract BUSCO sequences from the extracted chr
    """
    input:
        fna = expand("data/assemblies/{accession}/genomic.fna", accession=UNCURATED),
        gff = expand("data/BUSCO/{accession}/single_copy_busco_sequences.gff", accession=UNCURATED)
    output:
        directory("data/BUSCO/{accession}/extracted_buscos")
    shell:
        """
        elt=' ' read -r -a array <<< "{UNCURATED}"
        for acc in ${{array[@]}};
        do
            python3 scripts/3_cds_extraction/python/extract_genomic_cds.py -f "data/assemblies/"$acc"/genomic.fna" -g data/BUSCO/"$acc"/single_copy_busco_sequences.gff -o data/BUSCO/"$acc"/extracted_buscos \
            && touch data/BUSCO/"$acc"/extracted.flag
        done
        """


##########################################
############ PROTEIN BUSCO ###############

rule extract_protein_ids:
    """
    Extract protein IDs for all BUSCO
    """
    input:
        table = expand("data/BUSCO/{accession}/run_eukaryota_odb12/full_table.tsv", accession=CURATED)
    output:
        prots = expand("data/BUSCO/{accession}/extracted_protein_ids", accession=CURATED)
    shell:
        """
        elt=' ' read -r -a array <<< "{CURATED}"
        for acc in ${{array[@]}};
        do
            python3 scripts/3_cds_extraction/python/extract_sequences_protein.py -i data/BUSCO/"$acc"/run_eukaryota_odb12/full_table.tsv -o data/BUSCO/"$acc"/extracted_protein_ids
        done
        """

checkpoint busco_extract_protein:
    """
    Extract BUSCO sequences based on protein IDs
    """
    input:
        prots = expand("data/BUSCO/{accession}/extracted_protein_ids", accession=CURATED),
        gff = expand("data/assemblies/{accession}/genomic.gff", accession=CURATED),
        fna = expand("data/assemblies/{accession}/genomic.fna", accession=CURATED)
    output:
        directory("data/BUSCO/{accession}/extracted_buscos")
    shell:
        """
        elt=' ' read -r -a array <<< "{CURATED}"
        for acc in ${{array[@]}};
        do
            python3 scripts/3_cds_extraction/python/extract_protein_cds.py -p data/BUSCO/"$acc"/extracted_protein_ids -f data/assemblies/"$acc"/genomic.fna -g data/assemblies/"$acc"/genomic.gff -o data/BUSCO/"$acc"/extracted_buscos \
            && touch data/BUSCO/"$acc"/extracted.flag
        done
        """

##########################################

def aggregate(wildcards):
    if UNCURATED == ACCESSNB:
        busco_output = checkpoints.busco_extract_genomic.get(accession=wildcards.accession).output[0]
    elif CURATED == ACCESSNB:
        busco_output = checkpoints.busco_extract_protein.get(accession=wildcards.accession).output[0]
    else:
        busco_output = checkpoints.busco_extract_genomic.get(accession=wildcards.accession).output[0] + checkpoints.busco_extract_protein.get(accession=wildcards.accession).output[0]
    return expand("data/BUSCO/{accession}/extracted_buscos/{busco}.fasta", accession=wildcards.accession, busco=glob_wildcards(os.path.join(busco_output, f"{{busco}}.fasta")).busco)

rule concatenate_buscos:
    """
    Concatenate all found BUSCOs from genomic data into a single file
    """
    input:
        aggregate
    output:
        busco = "data/BUSCO/{accession}/all_buscos.fa"
    shell:
        """
        elt=' ' read -r -a array <<< "{input}"
        for acc in ${{array[@]}};
        do
            cat data/BUSCO/"$acc"/extracted_buscos/*.fasta > data/BUSCO/"$acc"/all_buscos.fa
        done
        """

rule concatenate_all_buscos:
    """
    Concatenate BUSCO files of all species
    """
    input:
        busco = "data/BUSCO/{accession}/all_buscos.fa"
    output:
        busco_cat = "data/BUSCO/busco_full.fa"
    shell:
        """
        cat data/BUSCO/*/all_buscos.fa > data/BUSCO/busco_full.fa
        """

rule create_pair_list:
    """
    Create a list of pairs of BUSCOs to align
    """
    input:
        busco_cat = "data/BUSCO/busco_full.fa"
    output:
        pair_list = "data/BUSCO/list_pairs"
    shell:
        """
        python3 scripts/3_cds_extraction/python/create_pairs.py -i {input} -o {output}
        """

rule run_dnds_process:
    """
    Run the dNdS computation with seaview
    """
    input:
        busco_cat = "data/BUSCO/busco_full.fa",
        pair_list = "data/BUSCO/list_pairs"
    output:
        align = "results/aligned_buscos.KaKs"
    shell:
        """
        makeblastdb -in {input.busco_cat} -dbtype nucl -parse_seqids
        csh scripts/3_cds_extraction/csh/Aln_dNdS_run_all.csh {input.pair_list} {input.busco_cat} 1 {output}
        """
