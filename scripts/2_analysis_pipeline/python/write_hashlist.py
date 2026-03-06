import argparse
from os import path, walk

parser = argparse.ArgumentParser(description="Writes a simple text file meant for MIKE processing")

parser.add_argument('-i', '--input', type=str, required=True, help="minhash directory path")
parser.add_argument('-o', '--output', type=str, required=True, help="Text file output path")
parser.add_argument('-c', '--clade', type=str, required=True, help="")

args = parser.parse_args()

"""
Very simple script to write absolute paths to a set of given files into a text file
"""

clades = {}

with open(args.clade, "r") as reader:
    l = reader.readlines()
    for line in l:
        splitline = line.strip().split("\t")
        clades[splitline[2]] = splitline[3]

if not args.output.endswith("/"):
    args.output += "/"

for dirpath,_,filenames in walk(args.input):
    for f in filenames:
        if "hashlist.txt" in f:
            continue
        out_path = f"{args.output}{clades[f[4:-12]]}_hashlist.txt"
        if not path.exists(out_path):
            with open(out_path, "w") as writer:
                writer.write(dirpath.strip()+"/"+f.strip())
                writer.write('\n')
        else:
            with open(out_path, "a") as appender:
                appender.write(dirpath.strip()+"/"+f.strip())
                appender.write('\n')