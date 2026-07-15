import argparse
import os

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, help="Path to input list of species")
parser.add_argument("-d", "--distance", required=True, help="Path to input list of dS")
parser.add_argument("-l", "--level", required=True, help="Taxonomic level")
parser.add_argument("-o", "--output", required=True, help="Path to output folder")

args = parser.parse_args()

"""
TODO: Get all clusters and their species from filtered cluster file, generate pairs, and look for dS in final dS file to generate matrix
Maybe better to write pairs directly in file rather than parse them?
"""

def separate_by_cluster(clust_file: str):
    with open(clust_file, "r") as reader:
        for line in reader.readlines():
            cluster = line.strip().split("\t")[0]
            species = line.strip().split("\t")[1]
            if not cluster in clust_dict.keys():
                clust_dict[cluster] = []
            clust_dict[cluster].append(species)

def generate_output_text(dist_file: str):
    for cluster in clust_dict.keys():
        if not cluster in out_dict.keys():
            out_dict[cluster] = ""
        out_text = "SAMPLE\t"
        for i in range(0, len(clust_dict[cluster]), 1):
            out_text += clust_dict[cluster][i]
            if i < len(clust_dict[cluster])-1:
                out_text += "\t"
            else:
                out_text += "\n"
        for i in range(0, len(clust_dict[cluster]), 1):
            out_text += clust_dict[cluster][i] + "\t"
            for j in range(0, len(clust_dict[cluster]), 1):
                if i == j:
                    out_text += "0"
                    if i < len(clust_dict[cluster])-1:
                        out_text += "\t"
                    continue
                # MUST GET DS VALUES FROM FILE
                pair = [clust_dict[cluster][i], clust_dict[cluster][j]]
                dS = 99
                with open(dist_file, "r") as reader:
                    for l in reader.readlines():
                        splitline = l.strip().split("\t")
                        if (splitline[0] == pair[0] and splitline[1] == pair[1]) or (splitline[1] == pair[0] and splitline[0] == pair[1]):
                            dS = float(splitline[3])
                            break
                out_text += str(dS)
                if j < len(clust_dict[cluster])-1:
                    out_text += '\t'
                else:
                    out_text += '\n'
        out_dict[cluster] = out_text

clust_dict = {}
out_dict = {}

separate_by_cluster(args.input)
generate_output_text(args.distance)

if not args.output.endswith("/"):
    args.output += "/"

for cluster in clust_dict.keys():
    filepath = f"{args.output}cluster_{cluster}_matrix.txt"
    with open(filepath, "w") as writer:
        writer.write(out_dict[cluster])
