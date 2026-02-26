rule get_fna:
    """
    Get the fna file as tempory file
    """
    input:
        url_fna="data/assemblies/{accession}/url_genomic.fna.txt"
    output:
        file_fna=temp("data/assemblies/{accession}/genomic.fna")
    shell:
        """
        cd data/assemblies/{wildcards.accession}/ \
        && wget -q -i url_genomic.fna.txt -O genomic.fna.gz \
        && gunzip  genomic.fna.gz \
        """