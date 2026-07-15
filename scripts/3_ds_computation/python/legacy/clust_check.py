import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, type=str, help="Input clust file")
parser.add_argument("-o", "--output", required=True, type=str, help="Output file path")

args = parser.parse_args()

with open(args.input, "r") as reader:
    current_cluster = -1
    out_array = []
    proc_spec = []

    for line in reader.readlines():
        if "pairs_cluster_" in line:
            current_cluster = line.strip().split("_")[2]
        else:
            spec1 = line.strip().split("-")[0]
            spec2 = line.strip().split("-")[1]
            if spec1 not in proc_spec:
                out_array.append(spec1 + '\t' + current_cluster + '\n')
                proc_spec.append(spec1)
            if spec2 not in proc_spec:
                out_array.append(spec2 + '\t' + current_cluster + '\n')
                proc_spec.append(spec2)

with open(args.output, "w") as writer:
    for elt in out_array:
        writer.write(elt)
    