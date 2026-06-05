import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, type=str, help="Input matrix file")
parser.add_argument("-o", "--output", required=True, type=str, help="Output file path")
parser.add_argument("-c", "--clade", required=True, type=str, help="Clade")

args = parser.parse_args()

with open(args.input, "r") as reader:
    current_clade = args.clade
    out_array = []

    splitline = reader.readlines()[0].strip().split("\t")[1:]
    for elt in splitline:
        out_array.append(elt + '\t' + current_clade + '\n')

with open(args.output, "a") as writer:
    for elt in out_array:
        writer.write(elt)
    