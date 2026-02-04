import argparse
from os import path

parser = argparse.ArgumentParser(description="Writes a simple text file meant for MIKE sketching")

parser.add_argument('-i', '--input', type=str, required=True, help="KMC output file path")
parser.add_argument('-o', '--output', type=str, required=True, help="Text file output path")

args = parser.parse_args()

txt = path.abspath(args.input).strip()

with open(args.output, "w") as writer:
    writer.write(txt)