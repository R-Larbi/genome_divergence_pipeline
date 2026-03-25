import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-b", "--busco", required=True, help="Path to concatenated BUSCO fastas")
parser.add_argument("-c", "--clusters", required=True, help="Path to cluster file")
parser.add_argument("-o", "--output", required=True, help="Path to output folder")

args = parser.parse_args()

def get_tax_busco(busco_file: str):
    with open(busco_file, "r") as reader:
        l = reader.readlines()
        for line in l:
            if not line.startswith(">"):
                continue
            splitline = line[1:].strip().split("\t")[0].split("-")
            busco     = splitline[0]
            truncate  = splitline[1].strip().split(".")[0]
            tax       = splitline[1]
            if not busco in busco_dict.keys():
                busco_dict[busco] = []
            if not busco in b_truncate.keys():
                b_truncate[busco] = []
            busco_dict[busco].append(tax)
            b_truncate[busco].append(truncate)

def get_pairs(cluster_file: str):
    with open(cluster_file, "r") as reader:
        l = reader.readlines()
        for line in l:
            if line.strip() == "":
                continue
            line = line.strip().split("\t")
            clust_dict[line[1]] = line[0]
            if not line[0] in pair_dict.keys():
                pair_dict[line[0]] = []
            pair_dict[line[0]].append(line[1])

busco_dict = {}
b_truncate = {}
clust_dict = {}
pair_dict  = {}
get_tax_busco(args.busco)
get_pairs(args.clusters)

if not args.output.endswith("/"):
    args.output += "/"

with open(args.output + "cluster_pairs", "w") as writer:
    for clust in pair_dict.keys():
        for i in range(0, len(pair_dict[clust])-1, 1):
            for j in range(i+1, len(pair_dict[clust]), 1):
                for elt in b_truncate.values():
                    if not (pair_dict[clust][i] in elt and pair_dict[clust][j] in elt):
                        continue
                    if pair_dict[clust][i] < pair_dict[clust][j]:
                        writer.write(f"{pair_dict[clust][i]}-{pair_dict[clust][j]}\n")
                    elif pair_dict[clust][i] > pair_dict[clust][j]:
                        writer.write(f"{pair_dict[clust][j]}-{pair_dict[clust][i]}\n")

with open(args.output+"busco_pairs", "w") as writer:
    for busco in busco_dict.keys():
        if len(busco_dict[busco]) <= 1:
            continue
        for i in range(0, len(busco_dict[busco])-1, 1):
            for j in range(i+1, len(busco_dict[busco]), 1):
                trunc_busco_i = busco_dict[busco][i].strip().split(".")[0]
                trunc_busco_j = busco_dict[busco][j].strip().split(".")[0]
                if not trunc_busco_i in clust_dict.keys() or not trunc_busco_j in clust_dict.keys():
                    continue
                if clust_dict[trunc_busco_i] == clust_dict[trunc_busco_j]:
                    if busco_dict[busco][i] < busco_dict[busco][j]:
                        writer.write(f"{busco}-{busco_dict[busco][i]}\t{busco}-{busco_dict[busco][j]}\n")
                    elif busco_dict[busco][i] > busco_dict[busco][j]:
                        writer.write(f"{busco}-{busco_dict[busco][j]}\t{busco}-{busco_dict[busco][i]}\n")