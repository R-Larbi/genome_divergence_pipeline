import argparse

parser = argparse.ArgumentParser(description="Converts the distance matrix to replace accession numbers with species names.")

parser.add_argument('-d', '--dist', required=True, help="Path to the distance matrix")
parser.add_argument('-i', '--info', required=True, help="Path to the organisms data file")
parser.add_argument('-o', '--output', required=True, help="Path for output file")

args = parser.parse_args()

"""
Small script for generating a secondary distance matrix with accession numbers replaced by species names.
"""

names = {}

# Open organisms data file to get all name-number associations
with open(args.info, "r") as reader:
# Pass the first line which is the headers
    l = reader.readline()
    l = reader.readline()
    while l:
# Split line and take both accession number ([2]) and species name ([2])
# Dictionary formatted in that manner: {Accession Number: Species Name}
        l = l.strip().split('\t')
        names[l[2].split('.')[0]] = l[0]
        l = reader.readline()

# Open distance matrix and output file
with open(args.dist, "r") as reader:
    with open(args.output, "w") as writer:
# First line is headers, all are accession numbers to replace
        fl = reader.readline().strip().split("\t")
        for elt in fl:
# First column is always "SAMPLE" so we ignore it
# In the current pipeline, acc numbers are preceded by "kmc_" which we must remove
            if elt != "SAMPLE":
                elt = elt[4:]
            if elt in names.keys():
                elt = names[elt]
            writer.write(elt+'\t')
        writer.write('\n')
        l = reader.readline()
# For following lines, only the first column has the accession number
        while l:
            l = l.strip().split('\t')
            l[0] = l[0][4:]
            if l[0] in names.keys():
                l[0] = names[l[0]]
            writer.write('\t'.join(l)+'\n')
            l = reader.readline()
            