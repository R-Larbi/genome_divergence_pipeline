import argparse

parser = argparse.ArgumentParser(description="Script to separate buscos to align by pair")

parser.add_argument("-p", "--pair", required=True, type=str, help="Pair to extract")
parser.add_argument("-b", "--busco", required=True, type=str, help="Path to busco pairings")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output file")

args = parser.parse_args()

def extract_pairs(pair:str, busco:str) -> str:
    out_str = ""

    first  = pair.strip().split("-")[0]
    second = pair.strip().split("-")[1]
    with open(busco, "r") as reader:
        l = reader.readlines()
        for line in l:
            splitline = line.strip().split("\t")
            species_1 = splitline[0].split("-")[1]
            species_2 = splitline[1].split("-")[1]

            if (first in species_1 and second in species_2) or (first in species_2 and second in species_1):
                out_str += line
    return out_str

text = extract_pairs(args.pair, args.busco)

with open(args.output, "w") as writer:
    writer.write(text)