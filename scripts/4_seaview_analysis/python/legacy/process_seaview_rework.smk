import json
import glob

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

with open(pathResources + "filtered_organisms_data") as reader:
    """
    Creates the list of accession numbers
    """
    ACCESSNB = []
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        if line_data[-1] != 'None': # if there is an existing URL
            ACCESSNB.append(line_data[2])

FINAL = ACCESSNB

with open(pathResults + "full_list", "r") as reader:
    """
    Creates the list of pairs to pass through seaview
    """
    PAIRS = []
    FIRST = []
    for line in reader.readlines():
        PAIRS.append(line.strip())

def get_clades(wildcards):
    clades = [Path(x).stem for x in glob.glob(pathResults + f"Clades/*/")]
    return expand(pathResults + "Clades/{clade}/pairing_done.flag", clade=clades)

rule all:
    input:
        expand(pathResults + "seaview_alignment/Paired_Alignments/{pair}/full_alignment.dNdS", pair = PAIRS)
    shell:
        """
        awk 'FNR==1 && NR!=1 { next } { print }' {pathResults}seaview_alignment/Paired_Alignments/*/full_alignment.KaKs > {pathResults}full_alignment_summary.dNdS
        """

rule separate_by_pair:
    input:
        clust = pathResults + "Clades/{clade}/cluster_pairs",
        busco = pathResults + "Clades/{clade}/busco_pairs"
    output:
        flag  = temp(pathResults + "Clades/{clade}/pairing_done.flag"),

    shell:
        """
        while read p; do
            mkdir -p {pathResults}seaview_alignment/{wildcards.clade}/"$p"
            python3 {pathScripts}4_seaview_analysis/python/separate_by_pair.py -p "$p" -b {input.busco} -o {pathResults}seaview_alignment/{wildcards.clade}/"$p"/busco_pairs
        done <{input.clust}
        rm {input.clust}
        rm {input.busco}
        touch {output.flag}
        """


rule flag_check:
    input:
        get_clades
    output:
        pathResults + "seaview_alignment/Paired_Alignments/{pair}/busco_pairs"

rule make_blast_db:
    input:
        get_clades,
        busco = pathBUSCO + "busco_full.fa"
    output:
        pathBUSCO + "busco_full.fa.ndb",
        pathResults + "seaview_alignment/Paired_Alignments/{pair}/busco_pairs"

    shell:
        """
        makeblastdb -in {input.busco} -dbtype nucl -parse_seqids
        """

rule seaview:
    input:
        pairs = pathResults + "seaview_alignment/Paired_Alignments/{pair}/busco_pairs",
        busco = pathBUSCO + "busco_full.fa",
        db    = pathBUSCO + "busco_full.fa.ndb"
    output:
        pathResults + "seaview_alignment/Paired_Alignments/{pair}/per_busco_alingment.dNdS"
    shell:
        """
        csh scripts/4_seaview_analysis/csh/Aln_dNdS_run_all.csh {input.pairs} {input.busco} 1 {output}
        """

rule get_medians:
    input:
        pathResults + "seaview_alignment/Paired_Alignments/{pair}/per_busco_alingment.dNdS"
    output:
        pathResults + "seaview_alignment/Paired_Alignments/{pair}/full_alignment.dNdS"
    shell:
        """
        python3 {pathScripts}4_seaview_analysis/python/median_dnds.py -i {input} -o {output}
        """