import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input")
parser.add_argument("-o","--output", required=True, type=str, help="Path to output")

args = parser.parse_args()

clusters = {}

with open(args.input, "r") as reader:
    l = reader.readlines()
    for line in l:
        line = line.strip().split(" ")
        if not line[0] in clusters.keys():
            clusters[line[0]] = []
        clusters[line[0]].append(line[1])

with open(args.output, "w") as writer:
    for cluster in clusters.keys():
        for i in range(0, len(clusters[cluster])-1):
            for j in range(i+1, len(clusters[cluster])):
                writer.write(f"{clusters[cluster][i]}\t{clusters[cluster][j]}\n")
