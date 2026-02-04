import sys

# This script is used to solve the multi-rooted xml file problem detailed 
# in the fetch_data.smk snakefile.

with open(sys.argv[1]) as reader, open(sys.argv[2], 'w') as writer:
    data = reader.readlines()
    writer.write(data[0])
    writer.write(data[1])
    if 'DocumentSummarySet' not in data[1]:
        writer.write('<DocumentSummarySet>\n')
    for line in data[2:]:
        if 'DocumentSummarySet' not in line:
            writer.write(line)
    writer.write('</DocumentSummarySet>')