import argparse

parser = argparse.ArgumentParser(description="Script to only keep the nth tenth of an organisms data file")

parser.add_argument("-i", "--input", required=True, help="Path of input organisms data file")
parser.add_argument("-p", "--partition", required=True, default=1, help="Kept tenth of the file")
parser.add_argument("-o", "--output", required=True, help="Path of output data file")

args = parser.parse_args()

"""
Script that takes an organisms data file which is outputted by the data fetching workflow,
and returns a truncated version which only keeps the nth tenth of organisms.
This is to partition the workflow, allowing us to work on multiple machines at once.
"""

fl = ""
output = ""

with open(args.input, "r") as reader:
    l  = reader.readlines()
    # We keep the first line as it is important for formatting
    fl = l[0]
    rl = l[1:]

    # Getting the range to extract
    tenth = float(len(rl) / 10)

    # We reduce the start by one to account for arrays starting from 0
    start = (float(args.partition) - 1.) * float(tenth) 
    print(start)
    end   = start + tenth
    print(end)
    # The round method rounds down, so we do funky code to round up:
    # int will round the result down, and if there is a remainder, the comparison will equal True, thus adding one
    # We round up the start and round down the end
    start = int(start) + (start % 1 > 0)
    
    # Sometimes the end float for the last partition has a 0.999... decimal instead of being a whole.
    end   = int(end) + (end % 1 > 0.999)

    print(start)
    print(end)

    for line in rl[start:end]:
        output += line

with open(args.output, "w") as writer:
    writer.write(fl)
    writer.write(output)