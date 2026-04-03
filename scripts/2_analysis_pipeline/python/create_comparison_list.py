import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-r", "--representative", required=True, type=str, help="Path to representative")
parser.add_argument("-p", "--phyla", required=True, type=str, help="Path to phyla file")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output")
parser.add_argument("-f", "--flag", required=True, type=str, help="Path to error flag file")

args = parser.parse_args()

def preProcess(phyla:str):
    with open(phyla, "r") as reader:
        l = reader.readlines()
        for line in l:
            splitline = line.strip().split("\t")

            phylum  = splitline[0]
            species = splitline[1]
            clade   = splitline[2]
            p_dict[species.strip().split(".")[0]] = {"accession": species, "phylum": phylum, "clade": clade}

def getComparisons(data:dict, rep:str):
    with open(rep, "r") as reader:
        rep_sp = reader.readline().strip()
    if "." in rep_sp:
        rep_sp = rep_sp.strip().split(".")[0]

    clade_rep  = data[rep_sp]["clade"]
    phylum_rep = data[rep_sp]["phylum"]
    full_rep.append(data[rep_sp]["accession"])

    for key in data.keys():
        if data[key]["clade"] != clade_rep and data[key]["phylum"] == phylum_rep:
            out_list.append(data[key]["accession"])

p_dict = {}
preProcess(args.phyla)

full_rep = []
out_list = []
getComparisons(p_dict, args.representative)

with open(args.output, "w") as writer:
    for i in range(len(out_list)):
        writer.write(out_list[i])
        if i < len(out_list):
            writer.write("\n")

with open(args.representative, "w") as writer:
    writer.write(full_rep[0])

if out_list == []:
    with open(args.flag, 'w') as writer:
        writer.write("No other shared phylum")