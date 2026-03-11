import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input file")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output file")

args = parser.parse_args()

def get_pairs(data: str):
    with open(data, "r") as reader:
        l = reader.readlines()
        for line in l[1:]:
            splitline = line.strip().split(" ")
            seq1 = splitline[0].strip().split("-")[1]
            seq2 = splitline[1].strip().split("-")[1]
            dn   = float(splitline[2])
            ds   = float(splitline[3])

            pair = seq1 + "\t" + seq2

            if not pair in pair_dict.keys():
                pair_dict[pair] = {}
                pair_dict[pair]["dN"] = []
                pair_dict[pair]["dS"] = []
            pair_dict[pair]["dN"].append(dn)
            pair_dict[pair]["dS"].append(ds)

def compute_median(dx: list):
    if len(dx) % 2 != 0:
        return dx[len(dx) // 2]
    else:
        return dx[len(dx) // 2 - 1]

pair_dict = {}
get_pairs(args.input)

out_list = []

for key in pair_dict.keys():
    seq1 = key.strip().split("\t")[0]
    seq2 = key.strip().split("\t")[1]
    list_in = [seq1, seq2]

    dn = sorted(pair_dict[key]["dN"])
    ds = sorted(pair_dict[key]["dS"])

    median_dn = compute_median(dn)
    median_ds = compute_median(ds)

    if median_ds == 0:
        dn_ds = 0.
    else:
        dn_ds = median_dn/median_ds

    list_in.append(median_dn)
    list_in.append(median_ds)
    list_in.append(dn_ds)
    out_list.append(list_in)

with open(args.output, "w") as writer:
    writer.write("Species 1\tSpecies 2\tmedian dN\tmedian dS\tmedian dN/dS\n")
    for pair in out_list:
        writer.write(f"{pair[0]}\t{pair[1]}\t{pair[2]}\t{pair[3]}\t{pair[4]}\n")