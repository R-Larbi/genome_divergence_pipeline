import json

configfile: "scripts/3_evo_distance/config.json"
configfile: "scripts/1_fetch_data/config.json"

# Function to load JSON files
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Assign environment variables
globals().update(load_json("scripts/environment_path.json"))

part = str(config["partition"])

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

"""
Priority order:
get_fna        1
process_kmc    2
transform_kmc  3
write_filelist 4
sketch         5

This ensures that the temporary files are deleted before new ones are generated, saving disk space.
"""

rule all:
    """
    Get the distance matrix and its readable counterpart
    """

    input:
        expand(pathMinhash + "kmc_{accession}.minhash.jac", accession=FINAL)
    

rule get_fna:
    """
    Get the fna file as tempory file
    Disk space usage: 1500MB
    """
    input:
        url_fna = pathAssemblies + "{accession}/url_genomic.fna.txt"
    output:
        file_fna = temp(pathAssemblies + "{accession}/genomic.fna.gz")
    resources:
        disk_mb = 1500
    priority: 1
    shell:
        """
        wget -q -i {pathAssemblies}{wildcards.accession}/url_genomic.fna.txt -O {pathAssemblies}{wildcards.accession}/genomic.fna.gz
        """

rule process_kmc:
    """
    Execute kmc on each genome
    Disk space usage: 15000MB + 1500MB(fasta file) = 16500MB
    """
    input:
        fna = pathAssemblies + "{accession}/genomic.fna.gz"
    output:
        kmc_pre = temp(pathKMC + "{accession}/kmc_{accession}.kmc_pre"),
        kmc_suf = temp(pathKMC + "{accession}/kmc_{accession}.kmc_suf")
    params:
        kc        = config["k"],
        min_count = config["min_count"],
        max_count = config["max_count"],
        mem       = config["mem"]
    resources:
        disk_mb = 16500
    priority: 2
    shell:
        """
        kmc -k{params.kc} -ci{params.min_count} -cx{params.max_count} -t1 -m{params.mem} -hp -fm {input} {pathKMC}{wildcards.accession}/kmc_{wildcards.accession} {pathKMC}{wildcards.accession}
        """

rule transform_kmc:
    """
    Transform the kmc files into text
    Disk space usage: 72000MB + 15000MB(kmc files) = 87000MB
    """
    input:
        kmc_pre = pathKMC + "{accession}/kmc_{accession}.kmc_pre",
        kmc_suf = pathKMC + "{accession}/kmc_{accession}.kmc_suf"
    output:
        kmc_fin = temp(pathAssemblies + "{accession}/kmc_{accession}.txt")
    resources:
        disk_mb = 87000
    priority: 3
    shell:
        """
        kmc_tools transform {pathKMC}{wildcards.accession}/kmc_{wildcards.accession} sort . dump -s {pathAssemblies}{wildcards.accession}/kmc_{wildcards.accession}.txt
        """

rule write_filelist:
    """
    Write the filelist for MIKE sketching
    Disk space usage: 72000MB(kmc txt file)
    """
    input:
        kmc_fin  = pathAssemblies + "{accession}/kmc_{accession}.txt"
    output:
        filelist = temp(pathAssemblies + "{accession}/filelist.txt")
    resources:
        disk_mb = 72000
    priority: 4
    shell:
        """
        python3 {pathScripts}3_evo_distance/python/write_filelist.py -i {input} -o {output}
        """

rule sketch:
    """
    MIKE sketching process
    kmc_fin is specified but never used: this is so that it isn't prematurely deleted during rule write_filelist
    """
    input:
        kmc_fin  = pathAssemblies + "{accession}/kmc_{accession}.txt",
        filelist = pathAssemblies + "{accession}/filelist.txt"
    output:
        minhash = pathMinhash + "kmc_{accession}.minhash.jac"
    resources:
        disk_mb = 72000
    priority: 5
    shell:
        """
        ~/MIKE/src/mike sketch -t 1 -l {input.filelist} -d data/minhash
        """

########### MOVED TO PROCESS_DISTANCE_MATRIX ################

#rule write_hashlist:
#    """
#    Write the list of sketched files for MIKE processing
#    """
#    input:
#        expand(pathMinhash + "kmc_{accession}.minhash.jac", accession=ACCESSNB)
#    output:
#        hashlist = pathMinhash + "hashlist.txt"
#    shell:
#        """
#        python3 {pathScripts}3_evo_distance/python/write_hashlist.py -i {pathMinhash} -o {output}
#        """

#rule get_matrix:
#    """
#    Execute MIKE to get the distance matrix
#    """
#    input:
#        hashlist = pathMinhash + "hashlist.txt"
#    output:
#        matrix = pathResults + "dist.txt"
#    shell:
#        """
#        ~/MIKE/src/mike dist -l {input} -L {input} -d {pathResults}
#        """

#rule readable_matrix:
#    """
#    Cleans the distance matrix and generates a readable matrix where all accession numbers are replaced by species name
#    """
#    input:
#        matrix = pathResults + "dist.txt",
#        info   = pathResources + "organisms_data"
#    output:
#        hr_mat = pathResults + "hr_dist.txt"
#    shell:
#        """
#        python3 {pathScripts}3_evo_distance/python/hr_dist.py -d {input.matrix} -i {input.info} -o {output}
#        """
