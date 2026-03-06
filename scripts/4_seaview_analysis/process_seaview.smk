import json

configfile: "scripts/2_analysis_pipeline/config.json"
configfile: "scripts/1_fetch_data/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

with open(pathResources + part + "_organisms_data") as reader:
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
    input:
        pathResults + "full_alignment.KaKs"

rule seaview:
    input:
        pairs = pathResults + "total_pair_list"
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathResults + "full_alignment.KaKs"
    shell:
        """
        makeblastdb -in {input.busco} -dbtype nucl -parse_seqids
        csh scripts/3_cds_extraction/csh/Aln_dNdS_run_all.csh {input.pairs} {input.busco} 1 {output}
        """