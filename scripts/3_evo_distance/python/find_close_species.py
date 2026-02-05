import argparse

parser = argparse.ArgumentParser(description="Takes a distance matrix and generates a file listing closely related species.")

parser.add_argument("-i", "--input", required=True, help="Path to the distance matrix")
parser.add_argument("-o", "--output", required=True, help="Path for the output file")
parser.add_argument("-t", "--threshold", required=False, default=0.17, help="Distance threshold under which two species are considered close")


args = parser.parse_args()

"""
Script which takes in a distance matrix and outputs a list of closely related species.
The output file will have one line per species, with the first column being that species and the following ones being the related ones.
"""

# Dictionary of related species
# Formatted as such: {Species: [Relative1, Relative2,..., RelativeX]}
neighbors = {}
# Dictionary of indices for species in distance matrix
# Formatted as such: {Index: Species}
indices = {}

with open(args.input, "r") as reader:
# We use the first line to get all our species
    l = reader.readline().strip().split("\t")
    i = 1
    for elt in l[1:]:
        neighbors[elt] = []
        indices[i] = elt
        i += 1

# For each line, get the species and check for each column if the distance is above the threshold.
# If it is, we append the relative to the list of that species' relatives, and we append that species to the relative's list.
# The index allows us to only check a relationship once.
    l = reader.readline()
    i = 1
    while l:
        l = l.strip.split('\t')
        j = i+1
        while j < len(l):
            if l[j] < args.threshold:
                neighbors[l[0]].append(indices[j])
                neighbors[indices[j]].append[l[0]]
            j += 1
        i += 1
        l = reader.readline()

# Writing to output
with open(args.output, "w") as writer:
    writer.write("Species\tClosely related species\n")
    for i in range(len(indices.keys)+1):
        writer.write(indices[i]+"\t")
        for elt in neighbors[indices[i]]:
            writer.write(elt)
            if elt is neighbors[indices[i]][-1]:
                writer.write('\n')
            else:
                writer.write('\t')
            