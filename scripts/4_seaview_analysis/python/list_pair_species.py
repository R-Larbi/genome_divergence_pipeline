import argparse

parser = argparse.ArgumentParser(description="Script to create full list of pairs of species in each clade")

parser.add_argument("-i", "--input", required=True, type=str, help="Path to input cluster file")
parser.add_argument("-b", "--busco", required=True, type=str, help="Path to busco file")
parser.add_argument("-o", "--output", required=True, type=str, help="Path to output folder")

args = parser.parse_args()

def get_pairs(clust:str, busco:str):
    with open(clust, "r") as reader:
        l = reader.readlines()