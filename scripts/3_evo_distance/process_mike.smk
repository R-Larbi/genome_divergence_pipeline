configfile: "scripts/3_evo_distance/config.json"

with open("data/resources/organisms_data") as reader:
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
        matrix = "results/dist.txt",
        hr_mat = "results/hr_dist.txt"
    

rule get_fna:
    """
    Get the fna file as tempory file
    Disk space usage: 1500MB
    """
    input:
        url_fna="data/assemblies/{accession}/url_genomic.fna.txt"
    output:
        file_fna=temp("data/assemblies/{accession}/genomic.fna.gz")
    resources:
        disk_mb = 1500
    priority: 1
    shell:
        """
        cd data/assemblies/{wildcards.accession}/ \
        && wget -q -i url_genomic.fna.txt -O genomic.fna.gz
        """

rule process_kmc:
    """
    Execute kmc on each genome
    Disk space usage: 15000MB + 1500MB(fasta file) = 16500MB
    """
    input:
        fna="data/assemblies/{accession}/genomic.fna.gz"
    output:
        kmc_pre=temp("kmc_{accession}.kmc_pre"),
        kmc_suf=temp("kmc_{accession}.kmc_suf")
    params:
        kc=config["k"],
        min_count=config["min_count"],
        max_count=config["max_count"]
    resources:
        disk_mb = 16500
    priority: 2
    shell:
        """
        kmc -k{params.kc} -ci{params.min_count} -cx{params.max_count} -t8 -fm {input} kmc_{wildcards.accession} .
        """

rule transform_kmc:
    """
    Transform the kmc files into text
    Disk space usage: 72000MB + 15000MB(kmc files) = 87000MB
    """
    input:
        kmc_pre="kmc_{accession}.kmc_pre",
        kmc_suf="kmc_{accession}.kmc_suf"
    output:
        kmc_fin=temp("data/assemblies/{accession}/kmc_{accession}.txt")
    resources:
        disk_mb = 87000
    priority: 3
    shell:
        """
        kmc_tools transform kmc_{wildcards.accession} sort . dump -s data/assemblies/{wildcards.accession}/kmc_{wildcards.accession}.txt
        """

rule write_filelist:
    """
    Write the filelist for MIKE sketching
    Disk space usage: 72000MB(kmc txt file)
    """
    input:
        kmc_fin="data/assemblies/{accession}/kmc_{accession}.txt"
    output:
        filelist=temp("data/assemblies/{accession}/filelist.txt")
    resources:
        disk_mb = 72000
    priority: 4
    shell:
        """
        python3 scripts/3_evo_distance/python/write_filelist.py -i {input} -o {output}
        """

rule sketch:
    """
    MIKE sketching process
    kmc_fin is specified but never used: this is so that it isn't prematurely deleted during rule write_filelist
    """
    input:
        kmc_fin="data/assemblies/{accession}/kmc_{accession}.txt",
        filelist="data/assemblies/{accession}/filelist.txt"
    output:
        minhash="data/minhash/kmc_{accession}.minhash.jac"
    resources:
        disk_mb = 72000
    priority: 5
    shell:
        """
        ~/MIKE/src/mike sketch -t 10 -l {input.filelist} -d data/minhash
        """

rule write_hashlist:
    """
    Write the list of sketched files for MIKE processing
    """
    input:
        expand("data/minhash/kmc_{accession}.minhash.jac", accession=ACCESSNB)
    output:
        hashlist="data/minhash/hashlist.txt"
    shell:
        """
        python3 scripts/3_evo_distance/python/write_hashlist.py -i data/minhash -o {output}
        """

rule get_matrix:
    """
    Execute MIKE to get the distance matrix
    """
    input:
        hashlist="data/minhash/hashlist.txt"
    output:
        matrix = "results/dist.txt"
    shell:
        """
        ~/MIKE/src/mike dist -l {input} -L {input} -d results
        """

rule readable_matrix:
    """
    Cleans the distance matrix and generates a readable matrix where all accession numbers are replaced by species name
    """
    input:
        matrix = "results/dist.txt",
        info = "data/resources/organisms_data"
    output:
        hr_mat = "results/hr_dist.txt"
    shell:
        """
        python3 scripts/3_evo_distance/python/hr_dist.py -d {input.matrix} -i {input.info} -o {output}
        """