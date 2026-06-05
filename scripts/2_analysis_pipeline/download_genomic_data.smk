with open("organisms_data") as reader:
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
    Get the distance matrix and its readable counterpart
    """
    input:
        expand("/banques/EvoDrivers/assemblies/{accession}/genomic.fna.gz", accession = FINAL)

rule get_fna:
    """
    Get the fna file as tempory file
    Disk space usage: 1500MB
    """
    input:
        url_fna = pathAssemblies + "{accession}/url_genomic.fna.txt"
    output:
        file_fna = pathBank + "{accession}/genomic.fna.gz"
    resources:
        disk_mb = 1500
    shell:
        """
        wget -q -i {pathAssemblies}{wildcards.accession}/url_genomic.fna.txt -O {pathBank}{wildcards.accession}/genomic.fna.gz
        """

