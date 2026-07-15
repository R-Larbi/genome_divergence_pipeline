import argparse

parser = argparse.ArgumentParser(description="Script to separate clusters of the full cluster file into clades")

parser.add_argument("-f", "--full", required=True, type=str, help="Path to full cluster file")
parser.add_argument("-p", "--phyla", required=True, type=str, help="Path to phyla file")
parser.add_argument("-c", "--clade", required=True, type=str, help="Clade")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output file")

args = parser.parse_args()

"""
TODO:

Separate filtered_clustered_species into clade/clustered_species
Do so by first getting all species in clade from list_phyla,
then first getting all species from clade and their clusters from filtered_clustered_species,
then getting all species sharing a cluster
"""

def parsePhyla(phyla:str, clade:str):
    with open(phyla, "r") as reader:
        for line in reader.readlines():
            splitline = line.strip().split("\t")
            if splitline[2] == clade:
                spec_dict[splitline[1].split(".")[0]] = -1

def getClusters(full:str):
    with open(full, "r") as reader:
        for line in reader.readlines():
            splitline = line.strip().split("\t")
            if not splitline[1] in spec_dict.keys():
                continue
            spec_dict[splitline[1]] = splitline[0]

def getReps(full:str):
    with open(full, "r") as reader:
        for line in reader.readlines():
            splitline = line.strip().split("\t")
            if (not splitline[0] in spec_dict.values()) or (splitline[1] in spec_dict.keys()):
                continue
            spec_dict[splitline[1]] = splitline[0]


spec_dict = {}

parsePhyla(args.phyla, args.clade)
getClusters(args.full)
getReps(args.full)

with open(args.output, "w") as writer:
    for spec in spec_dict.keys():
        if spec_dict[spec] == -1:
            continue
        writer.write(str(spec_dict[spec]) + "\t" + str(spec) + "\n")