import argparse
from Bio import SeqIO
from Bio.Seq import Seq

parser = argparse.ArgumentParser(description="Script that takes a genomic fasta and a gff and returns the sequences trimmed with only CDS regions")

parser.add_argument("-f", "--fasta", required=True, help="Input genomic fasta")
parser.add_argument("-g", "--gff", required=True, help="Input gff to filter")
parser.add_argument("-o", "--output", required=True, help="Path to output fasta")
parser.add_argument("-a", "--accession", required=False, default="Unspecified", help="Accession number")

args = parser.parse_args()

outlist = []
output = {}

# Opening the gff:
with open(args.gff, "r") as reader:
    l = reader.readlines()
# Parsing through each fasta record
    for record in SeqIO.parse(args.fasta, "fasta"):
# Parsing through gff
        for line in l:
            if line.strip().endswith(".gff"):
                if output != {}:
                    if strand == "-":
                        final_seq = Seq(output["Sequence"]).reverse_complement()
                    else:
                        final_seq = output["Sequence"]
                    outlist.append([output["ID"], output["BUSCO"], final_seq])
                    output = {}
                busco_id = line.strip().split("/")[-1].split(".")[0]
# Skip if not the right record
            elif record.id != line.strip().split("\t")[0]:
                continue
            elif line.strip().split("\t")[2] == "mRNA":
                output["ID"] = record.id
                output["BUSCO"] = busco_id
                output["Sequence"] = ""
            elif line.strip().split("\t")[2] == "CDS":
                start  = int(line.strip().split("\t")[3])
                end    = int(line.strip().split("\t")[4])
                seq    = str(record.seq[start-1:end])
                strand = line.strip().split("\t")[6]
                if strand == "-":
                    output["Sequence"] = seq + output["Sequence"]
                else:
                    output["Sequence"] = output["Sequence"] + seq
        if output != {}:
            if strand == "-":
                final_seq = Seq(output["Sequence"]).reverse_complement()
            else:
                final_seq = output["Sequence"]
            outlist.append([output["ID"], output["BUSCO"], final_seq])


if not args.output.endswith("/"):
    args.output = args.output + "/"
# Writing to output

if not os.path.exists(args.output):
    os.mkdir(args.output)

for elt in outlist:
    with open(args.output + elt[1] + ".fasta", "w") as writer:
        writer.write(">"+elt[1]+"-"+args.accession+"\t"+ elt[0])
        writer.write("\n")
        for i in range(len(elt[2])):
            writer.write(elt[2][i])
# Line break every 60 characters, with also a check that this isn't the last character in the sequence.
            if (i+1) % 60 == 0 and i < len(elt[2]):
                writer.write("\n")
        writer.write("\n")
