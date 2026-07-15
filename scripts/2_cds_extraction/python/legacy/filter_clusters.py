import argparse

parser = argparse.ArgumentParser(description="Script to remove all orphan clusters from the workflow")

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input cluster file")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output cluster file")

args = parser.parse_args()

def filter_clusters(clusters:str) -> list:
## Dictionary formatted as follows: ID_cluster: [Accession1, Accession2, ...]
    clust_dict = {}
    with open(clusters, "r") as reader:
        l = reader.readlines()
        for line in l:
## Last line is always empty
            if line.strip() == "":
                continue
            splitline = line.strip().split("\t")
            clust_id  = splitline[0]
            acc_num   = splitline[1]

            if not clust_id in clust_dict.keys():
                clust_dict[clust_id] = []
            clust_dict[clust_id].append(acc_num)
    
    out_clust = []
    for key in clust_dict.keys():
## Ignore clusters with only one member
        if len(clust_dict[key]) <= 1:
            continue
        for elt in clust_dict[key]:
            out_clust.append(f"{key}\t{elt}\n")
    return out_clust

cluster_data = filter_clusters(args.input)

with open(args.output, "w") as writer:
    for elt in cluster_data:
        writer.write(elt)