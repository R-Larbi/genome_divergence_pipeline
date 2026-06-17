import argparse
import os

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input species list")
parser.add_argument("-t", "--taxa", required=True, type=str, help="Path to taxonomy file")
parser.add_argument("-l", "--level", required=True, type=str, help="Taxonomy level")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output pair file")
parser.add_argument("-s", "--singles", required=True, type=str, help="Path to output singletons file")

args = parser.parse_args()

"""
Script to read taxonomy file and output pairs of species at specific taxon level.
"""

## Function to get list of species to process
def getListSpecies(species_file: str):
    with open(species_file, "r") as reader:
        for line in reader.readlines():
            species_list.append(line.strip())

## Function to order species to process by specific taxonomic level
## Level is taken from arguments
def parseTaxa(tax_file: str):
    with open(tax_file, "r") as reader:
        for line in reader.readlines()[1:]:
            # Check for species in list
            species = line.strip().split('\t')[0]
            if not species in species_list:
                continue

            # Check for specified taxa
            # This will pair species that are not close to each other if they have an unspecified taxon,
            # although the clustering step will not associate distant species regardless
            taxon   = line.strip().split('\t')[level]
            if taxon == "":
                taxon = f"Unspecified{args.level}"

            if not taxon in tax_dict.keys():
                tax_dict[taxon] = []
            tax_dict[taxon].append(species)

## Function to get the pairs of species and singletons
def generatePairs(tax: dict):
    for taxon in tax.keys():
        if len(tax[taxon]) == 1:
            singles.append(tax[taxon][0])
        else:
            for i in range(0, len(tax[taxon])-1, 1):
                for j in range(i+1, len(tax[taxon]), 1):
                    output.append(f"{tax[taxon][i]}-{tax[taxon][j]}")


## Set the taxonomic level, defaults at Genus
level = 8
match args.level:
    case "Genus":
        level = 8
    case "Family":
        level = 7
    case "Order":
        level = 6
    case "Class":
        level = 5
    case "Phylum":
        level = 4
    case "Kingdom":
        level = 3

species_list = []
tax_dict     = {}

getListSpecies(args.input)
parseTaxa(args.taxa)

output  = []
singles = []

generatePairs(tax_dict)

with open(args.output, "w") as writer:
    for i in range(len(output)):
        writer.write(output[i])
        if i < len(output):
            writer.write("\n")

with open(args.singles, "w") as writer:
    for i in range(len(singles)):
        writer.write(singles[i])
        if i < len(singles):
            writer.write("\n")