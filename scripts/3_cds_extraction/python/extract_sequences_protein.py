import argparse

parser = argparse.ArgumentParser(description="Script to get a text file of sequences to extract from fasta")

parser.add_argument("-i", "--input", required=True, help="Input TSV from BUSCO execution")
parser.add_argument("-o", "--output", required=True, help="Output text file")
parser.add_argument("-a", "--accession", required=False, default="", help="Accession number")

args = parser.parse_args()

"""
Script that takes the output table of a BUSCO execution and returns a list of IDs of non-duplicate sequences.
"""

output = []

with open(args.input, "r") as reader:
    l = reader.readlines()[3:]
    for line in l:
        splitted = line.strip().split("\t")

        status = splitted[1]
        if status != "Complete":
            continue
        seq   = splitted[2]
        busco = splitted[0]

        output.append([seq, busco])

with open(args.output, "w") as writer:
    for s in output:
        writer.write(s[0] + "\t" + s[1] + "\t" + args.accession)
        if s is not output[-1]:
            writer.write("\n")

