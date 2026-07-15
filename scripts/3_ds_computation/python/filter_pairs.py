import argparse

parser = argparse.ArgumentParser(description="Script to remove all orphan clusters from the workflow")

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input dS file")
parser.add_argument("-t", "--threshold", required=True, type=float, help="dS threshold")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output pairs file")
parser.add_argument("-f", "--full", required=True, type=str, help="Path to output species list")

args = parser.parse_args()

def filter_pairs(ds_file:str) -> list:
## Dictionary formatted as follows: ID_cluster: [Accession1, Accession2, ...]
    with open(ds_file, "r") as reader:
        l = reader.readlines()
        for line in l[1:]:
            splitline = line.strip().split("\t")
            species_1 = splitline[0]
            species_2 = splitline[1]
            dS = float(splitline[3])

            if dS < args.threshold:
                pairs.append([species_1, species_2])
                if not species_1 in species_list:
                    species_list.append(species_1)
                if not species_2 in species_list:
                    species_list.append(species_2)
    
pairs = []
species_list = []
filter_pairs(args.input)

with open(args.output, "w") as writer:
    for elt in pairs:
        writer.write(f"{elt[0]}\t{elt[1]}\n")

with open(args.full, "w") as writer:
    for elt in species_list:
        writer.write(f"{elt}\n")