import argparse
from os import path, walk

parser = argparse.ArgumentParser(description="Writes a simple text file meant for MIKE processing")

parser.add_argument('-i', '--input', type=str, required=True, help="minhash directory path")
parser.add_argument('-o', '--output', type=str, required=True, help="Text file output path")

args = parser.parse_args()

with open(args.output, "w") as writer:
    for dirpath,_,filenames in walk(args.input):
        for f in filenames:
            if f == "hashlist.txt":
                continue
            writer.write(dirpath.strip()+"/"+f.strip())
            if f is not filenames[-1]:
                writer.write('\n')