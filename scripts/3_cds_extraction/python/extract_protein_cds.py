import argparse
import time
import os
import pandas as pd
from Bio import SeqIO
import gzip
import os
 
parser = argparse.ArgumentParser()

parser.add_argument('-f', '--fasta', type=str, required=True, help='Path to fasta genomic file')
parser.add_argument('-p', '--protein', type=str, required=True, help='Path to list of protein IDs')
parser.add_argument('-g', '--gff', type=str,required=True, help='Path to gff file')
parser.add_argument('-o', '--output', type=str, required=True, help='Output file path')
parser.add_argument("-a", "--accession", required=False, default="Unspecified", help="Accession number")

args = parser.parse_args()

## Function to read gff files and get chromosome,
# start and end for locus.
                    
def processGff(gff:str):
    with open(gff, 'r') as reader:
        print("Processing gff... (This may take several minutes)")        
        print("Reading gff...")
        for line in reader:
            if line.startswith('#'):
                continue
            if line.split('\t')[2] == 'CDS':
                prot_name   = "none"
                splitline   = line.split('\t')
                chrname     = splitline[0]
                strand      = splitline[6]
                cdspos      = [splitline[3], splitline[4]]
                cds_info    = splitline[8]
                flag_gene   = 0
                flag_prot   = 0
                
                xrefs = cds_info.split(';')[2].split(",")
                for xref in xrefs:
                    ref=xref.split(':')
                    if ref[0] == "GenBank"  or ref[0]== "Dbxref=GenBank":
                        prot_name = ref[1]
                        flag_prot = 1  
                    if ref[0] == "Genbank"  or ref[0] == "Dbxref=Genbank":
                        prot_name = ref[1]
                        flag_prot = 1  
                    if ref[0] == "NCBI_GP"  or ref[0] == "Dbxref=NCBI_GP":
                        prot_name = ref[1]
                        flag_prot = 1
                """
                if flag_prot == 0 :
                    print("Warning : No protein")
                if prot_name == "none":
                    print("WARNING: Unable to get protein name : ")
                    print(cds_info)
                """

                if prot_name in pos_dict.keys():
                    if strand == "-":
                        pos_dict[prot_name].insert(0, cdspos)
                        rev_dict[prot_name] = "-"
                    else:
                        pos_dict[prot_name].append(cdspos)
                        rev_dict[prot_name] = "+"
                    chr_list.append(chrname)
                    if not chrname in chr_prot_index.keys():
                        chr_prot_index[chrname] = []
                    if not prot_name in chr_prot_index[chrname]:
                        chr_prot_index[chrname].append(prot_name)


parsed = SeqIO.parse(args.fasta, "fasta")

busco_dict = {}
pos_dict   = {}
rev_dict   = {}
with open(args.protein, "r") as reader:
    l = reader.readlines()
    for line in l:
        splitted = line.strip().split("\t")
        busco_dict[splitted[0]] = splitted[1]
        pos_dict[splitted[0]]   = []
        rev_dict[splitted[0]]   = ""

chr_list       = []
chr_prot_index = {}
processGff(args.gff)

out_dict = {}

for record in parsed:
    if not record.id in chr_list:
        continue
    for prot in chr_prot_index[record.id]:
        seq = ""
        for pos in pos_dict[prot]:
            seq += record.seq[int(pos[0])-1:int(pos[1])]
        if rev_dict[prot] == "-":
            final_seq = seq.reverse_complement()
        else:
            final_seq = seq
        out_dict[busco_dict[prot]] = {"prot": prot, "seq": final_seq, "chr": record.id}

if not args.output.endswith("/"):
    args.output = args.output + "/"
# Writing to output

if not os.path.exists(args.output):
    os.mkdir(args.output)

for busco in out_dict.keys():
    with open(args.output + busco +".fasta", "w") as writer:
        writer.write(f">{busco}-{args.accession}\t{out_dict[busco]["chr"]}\tPROT_ID:{out_dict[busco]["prot"]}\n")
        for i in range(len(out_dict[busco]["seq"])):
            writer.write(out_dict[busco]["seq"][i])
# Line break every 60 characters, with also a check that this isn't the last character in the sequence.
            if (i+1) % 60 == 0 and i < len(out_dict[busco]["seq"]):
                writer.write("\n")
        writer.write("\n")
