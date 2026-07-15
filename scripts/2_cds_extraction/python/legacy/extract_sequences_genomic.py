import argparse
from Bio import SeqIO

parser = argparse.ArgumentParser(description="Script to filter a genomic fasta to get only sequences from positions of BUSCO")

parser.add_argument("-i", "--input", required=True, help="Input TSV from BUSCO execution")
parser.add_argument("-f", "--fasta", required=True, help="Input fasta to filter")
parser.add_argument("-o", "--output", required=True, help="Output fasta file")
parser.add_argument("-a", "--accession", required=False, default="", help="Accession number")

args = parser.parse_args()

"""
Script that takes the output table of a BUSCO execution and a genomic fasta,
and returns a filtered fasta where sequences are taken from positions of BUSCO.
"""

output = []

# Opening the table:
with open(args.input, "r") as reader:
    l = reader.readlines()[3:]
# Parsing through each fasta record
    for record in SeqIO.parse(args.fasta, "fasta"):
# For each line in the table:
# Get the ID, the strand, and the positions
        for line in l:
            splitted = line.strip().split("\t")
            fid    = splitted[2]
# If that line's ID is the currently parsed record's:
# Get the description and sequence for the output, using the table's positions to extract only the necessary.
            if fid == record.id:
                if fid == "NC_059179.1":
                    print(record.seq)
                output.append([record.description, str(record.seq)])


# Writing to output
with open(args.output, "w") as writer:
    for elt in output:
        writer.write(">"+elt[0]+" "+args.accession)
        writer.write("\n")
        for i in range(len(elt[1])):
            writer.write(elt[1][i])
# Line break every 60 characters, with also a check that this isn't the last character in the sequence.
            if (i+1) % 60 == 0 and i < len(elt[1]):
                writer.write("\n")
        writer.write("\n")