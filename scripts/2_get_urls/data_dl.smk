with open("data/resources/organisms_data") as reader:
    """
    Creates the list of URL that will be used for download
    """
    PATHLIST = []
    ACCESSNB = []
    for line in reader.readlines()[1:]:
        line_data = line.strip().split('\t')
        if line_data[-1] != 'None': # if there is an existing URL
            ACCESSNB.append(line_data[2])
            PATHLIST.append(f"{line_data[-1]}")

FINAL = ACCESSNB
PATHLIST = dict(zip(FINAL, PATHLIST))

rule all:
    input: 
        expand("data/assemblies/{accession}/url_genomic.fna.txt", accession=FINAL)

def GetPath(wildcards):
    return(PATHLIST[wildcards.accession])

rule download_genomic_data:
    params:
        http_path = GetPath
    input:
        "data/resources/organisms_data"
    output:
        "data/assemblies/{accession}/url_genomic.fna.txt"
    shell:
        """
        cd data/assemblies/{wildcards.accession}/ \
        && echo {params.http_path}_genomic.fna.gz > url_genomic.fna.txt\
        && cd ../../../
        """