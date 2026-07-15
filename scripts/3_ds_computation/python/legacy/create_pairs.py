import argparse
import os

parser = argparse.ArgumentParser()

parser.add_argument("-b", "--busco", required=True, help="Path to concatenated BUSCO fastas")
parser.add_argument("-c", "--clusters", required=True, help="Path to cluster file")
parser.add_argument("-l", "--list", required=False, help="Path to list of species to consider")
parser.add_argument("-o", "--output", required=True, help="Path to output folder")

args = parser.parse_args()

"""
Script which reads the concatenated BUSCO fasta and a clade's cluster file,
and return two lists: a list of pairs of species, and a list of pairs of buscos.
Some lines for printing are commented throughout the script: uncomment them if needed for debugging.
"""

def get_tax_busco(busco_file: str):
    print("Reading BUSCO file...")
    print("Opening file " + busco_file)
    with open(busco_file, "r") as reader:
        l = reader.readlines()
        print("Iterating through lines...")
        for line in l:
            if not line.startswith(">"):
                continue
            splitline = line[1:].strip().split("\t")[0].split("-")
            busco     = splitline[0]
            truncate  = splitline[1].strip().split(".")[0]
            tax       = splitline[1]
            if not busco in busco_dict.keys():
                busco_dict[busco] = []
            if not busco in b_truncate.keys():
                b_truncate[busco] = []
            busco_dict[busco].append(tax)
            b_truncate[busco].append(truncate)
    print("Reading done! Closing BUSCO file\n")

def get_pairs(cluster_file: str):
    print("Reading cluster file...")
    print("Opening file " + cluster_file)
    with open(cluster_file, "r") as reader:
        l = reader.readlines()
        print("Iterating through lines...")
        for line in l:
            if line.strip() == "":
                continue
            line = line.strip().split("\t")
            if acc_list != [] and line[1] not in acc_list:
                continue
            clust_dict[line[1]] = line[0]
            if not line[0] in pair_dict.keys():
                pair_dict[line[0]] = []
            pair_dict[line[0]].append(line[1])
    print("Reading done! Closing cluster file\n")

def write_clusters(cluster_output: str, cluster: str):
    with open(cluster_output, "w") as writer:
        print("Writing cluster pairs...")
        print("Writing in file " + cluster_output)
        processed_pairs = []
        print(f"Size of pairing dictionary for cluster {cluster}: {len(pair_dict[cluster])}")
        for busco in b_truncate.keys():
            if len(busco_dict[busco]) <= 1:
                #print("/!\\ WARNING: One or less species found with current BUSCO, skipping /!\\")
                continue
            busco_filt = [b for b in busco_dict[busco] if b.strip().split(".")[0] in pair_dict[cluster]]
            for i in range(0, len(busco_filt)-1, 1):
                #print(f"Pairing species {pair_dict[cluster][i]}...")
                for j in range(i+1, len(busco_filt), 1):
                    #print(f"...with species {pair_dict[cluster][j]}")
                    """
                    if [busco_filt[i], busco_filt[j]] in processed_pairs:
                        continue
                    """
                    if busco_filt[i] < busco_filt[j]:
                        processed_pairs.append(f"{busco_filt[i]}-{busco_filt[j]}\n")
                    elif busco_filt[i] > busco_filt[j]:
                        processed_pairs.append(f"{busco_filt[j]}-{busco_filt[i]}\n")
                    #print(f"Match found for BUSCO {busco}")
        
        processed_pairs = set(processed_pairs)
        for pair in processed_pairs:
            writer.write(pair)
        print("Writing done! Closing cluster pair file\n")

def write_busco(busco_output: str, cluster: str):
    with open(busco_output, "w") as writer:
        print("Writing BUSCO pairs...")
        print("Writing in file " + busco_output)
        for busco in busco_dict.keys():
            #print("Getting pairs for BUSCO " + busco)
            if len(busco_dict[busco]) <= 1:
                #print("/!\\ WARNING: One or less species found with current BUSCO, skipping /!\\")
                continue
            #print("Number of species with BUSCO: " + str(len(busco_dict[busco])))
            for i in range(0, len(busco_dict[busco])-1, 1):
                for j in range(i+1, len(busco_dict[busco]), 1):
                    trunc_busco_i = busco_dict[busco][i].strip().split(".")[0]
                    trunc_busco_j = busco_dict[busco][j].strip().split(".")[0]
                    if not trunc_busco_i in clust_dict.keys() or not trunc_busco_j in clust_dict.keys():
                        continue
                    if clust_dict[trunc_busco_i] == cluster and clust_dict[trunc_busco_j] == cluster:
                        if busco_dict[busco][i] < busco_dict[busco][j]:
                            writer.write(f"{busco}-{busco_dict[busco][i]}\t{busco}-{busco_dict[busco][j]}\n")
                        elif busco_dict[busco][i] > busco_dict[busco][j]:
                            writer.write(f"{busco}-{busco_dict[busco][j]}\t{busco}-{busco_dict[busco][i]}\n")
        print("Writing done! Closing busco pair file\n")

def remove_duplicates(array: list) -> list:
  seen = []
  new_array = []
  for element in array:
    if element not in seen:
      seen.append(element)
      new_array.append(element)
  return new_array

acc_list = []
if args.list is not None:
    with open(args.list, "r") as reader:
        for line in reader.readlines():
            acc_list.append(line.strip().split(".")[0])

busco_dict = {}
b_truncate = {}
clust_dict = {}
pair_dict  = {}
get_tax_busco(args.busco)
get_pairs(args.clusters)

print("Filtering BUSCO dictionary to only include species from processed clusters...")
for busco in busco_dict.keys():
    #print("Filtering BUSCO " + busco)
    busco_dict[busco] = [b for b in busco_dict[busco] if b.strip().split(".")[0] in clust_dict.keys()]
    b_truncate[busco] = [b for b in b_truncate[busco] if b in clust_dict.keys()]
print("Filtering done!\n")

if not args.output.endswith("/"):
    args.output += "/"

for cluster in pair_dict.keys():
    
    if os.path.isfile(args.output + "pairs_cluster_" + cluster):
        continue
    cluster_out = args.output + "pairs_cluster_" + cluster
    write_clusters(cluster_out, cluster)
    
    if os.path.isfile(args.output + "busco_cluster_" + cluster):
        continue
    busco_out = args.output + "busco_cluster_" + cluster
    write_busco(busco_out, cluster)


