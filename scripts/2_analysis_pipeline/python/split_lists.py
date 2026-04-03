import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output")

args = parser.parse_args()

out = []
with open(args.input, "r") as reader:
    l = reader.readlines()
    text = ""
    for i in range(len(l[0].strip())):
        text += l[0].strip()[i]
        if (i+1) % 27 == 0:
            out.append(text)
            text = ""

with open(args.output, "w") as writer:
    for i in range(len(out)):
        writer.write(out[i])
        writer.write("\n")