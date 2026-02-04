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

rule all:
    """
    Get the distance matrix
    """

    input:
        matrix = "results/dist.txt"
    

rule get_fna:
    """
    Get the fna file as tempory file
    """
    input:
        url_fna="data/assemblies/{accession}/url_genomic.fna.txt"
    output:
        file_fna="data/assemblies/{accession}/genomic.fna.gz"
    shell:
        """
        cd data/assemblies/{wildcards.accession}/ \
        && wget -q -i url_genomic.fna.txt -O genomic.fna.gz
        """

rule process_kmc:
    """
    Execute kmc on each genome
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
    shell:
        """
        kmc -k{params.kc} -ci{params.min_count} -cx{params.max_count} -t8 -fm {input} kmc_{wildcards.accession} .
        """

rule transform_kmc:
    """
    Transform the kmc files into text
    """
    input:
        kmc_pre="kmc_{accession}.kmc_pre",
        kmc_suf="kmc_{accession}.kmc_suf"
    output:
        kmc_fin=temp("data/assemblies/{accession}/kmc_{accession}.txt")
    shell:
        """
        kmc_tools transform kmc_{wildcards.accession} sort . dump -s data/assemblies/{wildcards.accession}/kmc_{wildcards.accession}.txt
        """

rule write_filelist:
    """
    Write the filelist for MIKE sketching
    """
    input:
        kmc_fin="data/assemblies/{accession}/kmc_{accession}.txt"
    output:
        filelist=temp("data/assemblies/{accession}/filelist.txt")
    shell:
        """
        touch data/assemblies/{wildcards.accession}/filelist.txt &&
        chmod +wr data/assemblies/{wildcards.accession}/filelist.txt &&
        python3 scripts/3_evo_distance/python/write_filelist.py -i {input} -o {output}
        """

rule sketch:
    """
    MIKE sketching process
    """
    input:
        kmc_fin="data/assemblies/{accession}/kmc_{accession}.txt",
        filelist="data/assemblies/{accession}/filelist.txt"
    output:
        minhash="data/minhash/kmc_{accession}.minhash.jac"
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
        touch data/minhash/hashlist.txt &&
        chmod +wr data/minhash/hashlist.txt &&
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