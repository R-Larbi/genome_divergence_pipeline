import argparse

parser = argparse.ArgumentParser(description="Script to only keep the nth tenth of an organisms data file")

parser.add_argument("-i", "--input", required=True, help="Path of input organisms data file")
parser.add_argument("-p", "--partition", required=False, default=1, help="Kept tenth of the file")
parser.add_argument("-m", "--max_part", required=False, default=10, help="Number of partitions")
parser.add_argument("-o", "--output", required=True, help="Path of output data file")

args = parser.parse_args()

"""
Script that takes an organisms data file which is outputted by the data fetching workflow,
and returns a truncated version which only keeps the nth tenth of organisms.
This is to partition the workflow, allowing us to work on multiple machines at once.
"""

fl = ""
output = ""

max_part = args.max_part
part = args.partition

with open(args.input, "r") as reader:
    l  = reader.readlines()
    # We keep the first line as it is important for formatting
    fl = l[0]
    rl = l[1:]

    # Getting the range to extract
    fract = float(len(rl) / max_part)

    # We reduce the start by one to account for arrays starting from 0
    start = (float(part) - 1.) * float(fract)
    end   = start + fract

    # We round up the start and end
    start = int(start)

    # Sometimes the end float for the last partition has a 0.999... decimal instead of being a whole.
    end   = int(end) + (end % 1 > 0.999)

    for line in rl[start:end]:
        output += line

with open(args.output, "w") as writer:
    writer.write(fl)
    writer.write(output)