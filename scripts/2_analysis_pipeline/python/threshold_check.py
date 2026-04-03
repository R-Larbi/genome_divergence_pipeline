import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-d", "--distance", required=True, type=str, help="Path to distance matrix")
parser.add_argument("-p", "--pairs", required=True, type=str, help="Path to pair list file")
parser.add_argument("-t", "--threshold", required=True, type=float, help="Distance threshold")

args = parser.parse_args()
"""
def processMatrix(dist:str):
    with open(dist, "r") as reader:
        l = reader.readlines()
        mat_dist = float(l[1].strip().split("\t")[2])
        if mat_dist <= args.threshold:
            distance = mat_dist
            flag = 1

flag = 0
distance = 0
processMatrix(args.distance)
"""

def processMatrix(dist:str):
    with open(dist, "r") as reader:
        l = reader.readlines()
        rep.append(l[1].strip().split("\t")[0])

        for i in range(1, len(l[0].strip().split("\t")[1:]), 1):
            if float(l[1].strip().split("\t")[i]) > args.threshold:
                continue
            dist_list.append(l[0].strip().split("\t")[i])

rep = []
dist_list = []
processMatrix(args.distance)

if dist_list != []:
    with open(args.pairs, "w") as writer:
        for i in range(len(dist_list)):
            writer.write(rep[0].strip().split("kmc_")[1] + "\t" + dist_list[i].strip().split("kmc_")[1])
            if i < len(dist_list):
                writer.write("\n")
else:
    with open(args.pairs, "w") as writer:
        pass