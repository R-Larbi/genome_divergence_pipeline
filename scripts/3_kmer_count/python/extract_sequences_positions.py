import argparse

parser = argparse.ArgumentParser(description="Script to filter a genomic fasta to get only sequences from positions of BUSCO")

parser.add_argument("-i", "--input", required=True, help="Input TSV from BUSCO execution")
parser.add_argument("-f", "--fasta", required=True, help="Input fasta to filter")
parser.add_argument("-o", "--output", required=True, help="Output fasta file")

args = parser.parse_args()

"""
Script that takes the output table of a BUSCO execution and a genomic fasta,
and returns a filtered fasta where sequences are taken from positions of BUSCO.
"""

output = []

with open(args.input, "r") as reader:
    l = reader.readlines()[3:]
    for line in l:
        splitted = line.strip().split("\t")

        status = splitted[1]
        if status != "Complete":
            continue
        seq = splitted[2]

        output.append(seq)

with open(args.output, "w") as writer:
    for s in output:
        writer.write(s)
        if s is not output[-1]:
            writer.write("\n")

