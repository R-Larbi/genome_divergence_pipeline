
rule get_prot_fasta:
     """
     Get the protein fasta file as tempory file
     """
     input:
         url_prot_fasta="data/assemblies/{accession}/url_protein.faa.txt"
     output:
         file_faa="data/assemblies/{accession}/protein.faa"
     shell:
         """
         cd data/assemblies/{wildcards.accession}/ \
         && wget -q -i url_protein.faa.txt -O protein.faa.gz \
         && gunzip  protein.faa.gz \
         """
