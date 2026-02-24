import argparse
import pandas as pd
import hdbscan

parser = argparse.ArgumentParser(description="Takes a distance matrix and generates a file listing closely related species.")

parser.add_argument("-i", "--input", required=True, help="Path to the distance matrix")
parser.add_argument("-o", "--output", required=True, help="Path for the output file")


args = parser.parse_args()

species = []

matrix = pd.read_csv(args.input, sep="\t")
species = matrix.iloc[:,0].to_list()
matrix = matrix.iloc[:, 1:-1]


clusterer = hdbscan.HDBSCAN(metric="precomputed", min_cluster_size=3, min_samples=1, cluster_selection_epsilon = .1)

clusterer.fit(matrix)

with open(args.output, "w") as writer:
    for i in range(len(clusterer.labels_)):
        species[i] = [species[i], clusterer.labels_[i]]
    ordered_labels = set(clusterer.labels_)

    for label in ordered_labels:
        writer.write("Cluster " + str(label) + ": ")
        for i in range(len(species)):
            if species[i][1] == label:
                writer.write(species[i][0] + " ")
        writer.write("\n")
    writer.write(str(clusterer.labels_) + "\n")
    writer.write(str(clusterer) + "\n")