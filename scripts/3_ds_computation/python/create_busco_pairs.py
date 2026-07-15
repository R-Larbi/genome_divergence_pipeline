import argparse
import os

parser = argparse.ArgumentParser()

parser.add_argument("-b", "--busco", required=True, help="Path to concatenated BUSCO fastas")
parser.add_argument("-i", "--input", required=False, help="Path to input list of species")
parser.add_argument("-o", "--output", required=True, help="Path to output file")

args = parser.parse_args()

"""
Script which reads the concatenated BUSCO fasta and a list of pairs, and return a list of pairs of buscos.
Some lines for printing are commented throughout the script: uncomment them if needed for debugging.
"""

def get_tax_busco(busco_file: str):
    print("Reading BUSCO file...")
    print("Opening file " + busco_file)
    with open(busco_file, "r") as reader:
        l = reader.readlines()
        print("Iterating through lines...")
        for line in l:
            if not line.startswith(">"):
                continue
            splitline = line[1:].strip().split("\t")[0].split("-")
            busco     = splitline[0]
            tax       = splitline[1]
            if not tax in busco_dict.keys():
                busco_dict[tax] = []
            busco_dict[tax].append(busco)
    print("Reading done! Closing BUSCO file\n")

def get_pairs(pair_file: str):
    print("Reading pair file...")
    print("Opening file " + pair_file)
    with open(pair_file, "r") as reader:
        l = reader.readlines()
        print("Iterating through lines...")
        for line in l:
            if line.strip() == "":
                continue
            if not line.strip() in pair_list:
                pair_list.append(line.strip())
            species1 = line.strip().split("-")[0]
            species2 = line.strip().split("-")[1]
            if not species1 in species_list:
                species_list.append(species1)
            if not species2 in species_list:
                species_list.append(species2)
    print("Reading done! Closing pair file\n")

def write_busco(busco_output: str):
    with open(busco_output, "w") as writer:
        print("Writing BUSCO pairs...")
        print("Writing in file " + busco_output)
        for pair in pair_list:
            species1 = pair.split("-")[0]
            if not species1 in busco_dict.keys():
                if not species1 in no_b_list:
                    no_b_list.append(species1)
                continue
            species2 = pair.split("-")[1]
            if not species2 in busco_dict.keys():
                if not species2 in no_b_list:
                    no_b_list.append(species2)
                continue
            for busco in busco_dict[species1]:
                if not busco in busco_dict[species2]:
                    continue
                if species1 < species2:
                    writer.write(f"{busco}-{species1}\t{busco}-{species2}\n")
                elif species1 > species2:
                    writer.write(f"{busco}-{species2}\t{busco}-{species1}\n")
        print("Writing done! Closing busco pair file\n")

def write_no_buscos(no_busco_output: str):
    """
    Writes an output log file which specifies which species did not have BUSCO genes in the BUSCO database.
    """
    with open(no_busco_output, "w") as writer:
        for no_b in no_b_list:
            writer.write(no_b + "\n")

busco_dict   = {}
species_list = []
pair_list    = []
no_b_list    = []
get_tax_busco(args.busco)
get_pairs(args.input)

print("Filtering BUSCO dictionary to only include species from processed clusters...")
entries_to_remove = [t for t in busco_dict.keys() if t not in species_list]
for entry in entries_to_remove:
    busco_dict.pop(entry, None)
print("Filtering done!\n")

write_busco(args.output)
write_no_buscos("results/list_species_with_no_buscos")