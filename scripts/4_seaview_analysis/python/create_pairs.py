import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, help="Path to concatenated BUSCO fastas")
parser.add_argument("-c", "--clusters", required=True, help="Path to cluster file")
parser.add_argument("-o", "--output", required=True, help="Path to output")

args = parser.parse_args()

def get_tax_busco(busco_file: str):
    with open(busco_file, "r") as reader:
        l = reader.readlines()
        for line in l:
            if not line.startswith(">"):
                continue
            splitline = line[1:].strip().split("\t")[0].split("-")
            busco     = splitline[0]
            tax       = splitline[1]
            if not busco in busco_dict.keys():
                busco_dict[busco] = []
            busco_dict[busco].append(tax)

def get_pairs(cluster_file: str):
    with open(cluster_file, "r") as reader:
        l = reader.readlines()
        for line in l:
            if line.strip() == "":
                continue
            line = line.strip().split("\t")
            clust_dict[line[1]] = line[0]

busco_dict = {}
clust_dict = {}
get_tax_busco(args.input)
get_pairs(args.clusters)

with open(args.output, "w") as writer:
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
                    writer.write(f"{busco}-{busco_dict[busco][i]}\t{busco}-{busco_dict[busco][j]}\n")