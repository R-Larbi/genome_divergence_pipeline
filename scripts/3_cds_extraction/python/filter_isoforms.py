from Bio import SeqIO
import sys
import argparse

parser = argparse.ArgumentParser(description="")

parser.add_argument("-f", "--fasta", required=True, help="Path to protein fasta")
parser.add_argument("-g", "--gff", required=True, help="Path to gff")
parser.add_argument("-o", "--output", required=True, help="Output path")

args = parser.parse_args()

def processGff(gff:str):
    with open(gff, "r") as reader:
        l = reader.readlines()
        for line in l:
            splitted = line.strip().split("\t")
            if len(splitted) < 3:
                continue
            if splitted[2] != "gene" and splitted[2] != "CDS":
                continue
            start  = int(splitted[3])
            end    = int(splitted[4])
            length = end - start

            data  = splitted[8]
            flag_gene = 0
            flag_prot = 0
            flag = 0
            last_prot = ""
            prot_length = 0

            xrefs = data.split(';')[2].split(",")
            if splitted[2] == "gene":
                for xref in xrefs:
                    ref=xref.split(':')
                    if ref[0] == "Dbxref=GeneID" or ref[0] == "GeneID":
                        gene_id = ref[1]
                        gene_dict[gene_id] = {"Longest": 0, "Prot": ""}
                        flag = 1
                if flag == 0 :
                    xrefs = data.split(';')[1].split(",")
                    for xref in xrefs:
                        ref=xref.split(':')
                        if ref[0] == "Dbxref=GeneID" or ref[0] == "GeneID":
                            gene_id = ref[1]
                            gene_dict[gene_id] = {"Longest": 0, "Prot": ""}
                            flag = 1
                if flag == 0 :
                    xrefs = data.split(';')
                    for xref in xrefs:
                        ref=xref.split('=')
                        if ref[0] == "locus_tag" :
                            gene_id = ref[1].rstrip()
                            gene_dict[gene_id] = {"Longest": 0, "Prot": ""}
                            flag = 1
                if flag == 0 :
                    print("debug2 "+ data.split(';')[2])
            
            elif splitted[2] == "CDS":
                xrefs = data.split(';')[2].split(",")
                for xref in xrefs:
                    ref=xref.split(':')
                    if ref[0] == "Dbxref=GeneID" or ref[0] == "GeneID" :
                        cds_gene_id = ref[1]
                        flag_gene = 1
                    if ref[0] == "GenBank"  or ref[0]== "Dbxref=GenBank":
                        prot_name = ref[1]
                        flag_prot = 1  
                    if ref[0] == "Genbank"  or ref[0] == "Dbxref=Genbank":
                        prot_name = ref[1]
                        flag_prot = 1  
                    if ref[0] == "NCBI_GP"  or ref[0] == "Dbxref=NCBI_GP":
                        prot_name = ref[1]
                        flag_prot = 1
                if flag_gene == 0 :
                    xrefs = data.split(';')
                    for xref in xrefs:
                        ref=xref.split('=')
                        if ref[0] == "locus_tag" :
                            cds_gene_id = ref[1]
                            flag_gene = 1
                if gene_dict[cds_gene_id]["Prot"] == prot_name:
                    gene_dict[cds_gene_id]["Longest"] += length
                else:
                    if last_prot == prot_name:
                        prot_length += length
                    else:
                        last_prot = prot_name
                        prot_length = length
                    if prot_length >= gene_dict[cds_gene_id]["Longest"]:
                        gene_dict[cds_gene_id]["Longest"] = prot_length
                        gene_dict[cds_gene_id]["Prot"] = prot_name

gene_dict = {}
processGff(args.gff)
prot_list = []
for key in gene_dict.keys():
    prot_list.append(gene_dict[key]["Prot"])


with open(args.output, "w") as writer:
    for rec in SeqIO.parse(args.fasta, "fasta"):
        if not rec.id in prot_list:
            continue
        SeqIO.write(rec, writer, "fasta")
