import argparse
import pandas as pd
import hdbscan

parser = argparse.ArgumentParser(description="Takes a distance matrix and generates a file listing closely related species.")

parser.add_argument("-i", "--input", required=True, help="Path to the distance matrix")
parser.add_argument("-o", "--output", required=True, help="Path for the output file")
parser.add_argument("-t", "--threshold", required=False, default=0.17, help="Distance threshold under which two species are considered close")


args = parser.parse_args()

species = []

matrix = pd.read_csv(args.input, sep="\t")

species = matrix.iloc[0]

matrix = matrix.iloc[1:, 1:]

