import subprocess
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, help="Path to organisms data file")
parser.add_argument("-o", "--output", required=True, help="Path to output")

args = parser.parse_args()

clade_dict = {}

with open(args.input, "r") as reader:
    l = reader.readlines()
    for line in l[1:]:
        splitline = line.strip().split("\t")
        species   = splitline[0]
        taxid     = splitline[1]
        accession = splitline[2]

        info = subprocess.run(f"datasets summary taxonomy taxon '{species}'  --as-json-lines | dataformat tsv taxonomy --template 'tax-summary' |cut -f1,2,11,13,15,17 |tail -n1", shell=True, capture_output=True).stdout
        splitinfo = str(info)[2:-1].strip().split("\\t")
        clade = splitinfo[4]
        clade_dict[taxid] = [species, accession, clade]

with open(args.output, "w") as writer:
    for tax in clade_dict.keys():
        writer.write(f"{clade_dict[tax][0]}\t{tax}\t{clade_dict[tax][1]}\t{clade_dict[tax][2]}\n")