import argparse

parser = argparse.ArgumentParser(description="Script to clusterize species based on distance threshold")

parser.add_argument("-i", "--input", required=True, type=str, help="Input dnds file")
parser.add_argument("-t", "--threshold", required=True, default=1.0, type=float, help="dS threshold")
parser.add_argument("-o", "--output", required=True, type=str, help="Output file path")

args = parser.parse_args()

neighbors = []
parsed    = []

with open(args.input, "r") as reader:
    for line in reader.readlines()[1:]:
        print(line)
        splitline = line.strip().split("\t")
        if splitline[3] == "median dS":
            continue
        if float(splitline[3]) < 0.5:
            neighbors.append([splitline[0], splitline[1]])
            if splitline[0] not in parsed:
                parsed.append(splitline[0])
            if splitline[1] not in parsed:
                parsed.append(splitline[1])

print(len(parsed))

# Writing to output
with open(args.output, "w") as writer:
    for elt in neighbors:
        writer.write(f"{elt[0]}\t{elt[1]}\n")
            