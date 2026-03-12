import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input file")
parser.add_argument("-d", "--data", required=True, type=str, help="Path to organisms data file")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output file")

args = parser.parse_args()

def get_clusters(clust_file: str):
    print("Reading cluster file...")
    with open(clust_file, "r") as reader:
        l = reader.readlines()
        max_clade = 0
        modifier  = 0
        for line in l:
            if line.strip() == "":
                modifier  = max_clade + 1
                max_clade = 0
                continue
            splitline = line.strip().split("\t")

            clust     = int(splitline[0]) + modifier
            if int(clust) > max_clade:
                max_clade = clust
            
            species   = splitline[1]

            if not clust in clust_dict.keys():
                clust_dict[clust] = []
            clust_dict[clust].append(species)
            species_dict[species] = clust
    print("Reading done!")

def get_counts(org_data: str, sp_dict: dict, cl_dict: dict):
    print("Reading organisms data file...")
    out_str = ""
    with open(org_data, "r") as reader:
        l = reader.readlines()
        out_str += l[0]
        for line in l[1:]:
            splitline = line.strip().split("\t")
            accession = splitline[2].strip().split(".")[0]
            if not accession in species_dict.keys():
                print("Unknown accession in organisms data: " + accession)
                continue
            if len(clust_dict[species_dict[accession]]) <= 1:
                continue
            out_str += line
    print("Reading done!")
    return out_str

clust_dict   = {}
species_dict = {}
get_clusters(args.input)

out_str = get_counts(args.data, species_dict, clust_dict)

print("Writing to file...")
with open(args.output, "w") as writer:
    writer.write(out_str)
print("Written in file " + args.output) 
