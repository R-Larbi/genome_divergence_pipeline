## Script to attribute clustering level to each species
## Takes a taxonomy dataset of all the studied species and writes lists of absolute 
## paths to their hashed distance files clustered by clades of less than 1000 members

library(tools)
library(stringr)

args = commandArgs(trailingOnly=TRUE)

# Test if there is an argument: if not, return an error
if (length(args)==0 || length(args)==1) {
  stop("Rscript error: two arguments must be supplied (taxonomy dataset and accession list)", call.=FALSE)
} else if (length(args)>2) {
  stop("Rscript error: too many arguments detected, must only be two (taxonomy dataset and accession list)", call.=FALSE)
}

tax_data <- read.table(args[1], sep="\t", header=T)
acc_data <- scan(args[2], what=character(), sep="\n")
for (i in 1:length(acc_data)) {
  acc_data[i] <- str_remove_all(acc_data[i], "kmc_")
  acc_data[i] <- str_remove_all(acc_data[i], ".minhash.jac")
}

tax_data <- tax_data[tax_data$Assembly_Accession %in% acc_data,]
## Cleaning
tax_data$Kingdom[which(tax_data$Kingdom == "")] <- "OtherEukaryota"
tax_data$Phylum[which(tax_data$Phylum == "")] <- "NoPhylum"
tax_data$Class[which(tax_data$Class == "")] <- "NoClass"
tax_data$Order[which(tax_data$Order == "")] <- "NoOrder"
tax_data$Family[which(tax_data$Family == "")] <- "NoFamily"

## Getting names of clades with less than 1000 members
ki_df <- table(tax_data$Kingdom)
ki_1000 <- ki_df[which(ki_df < 1000)]

ph_df <- table(tax_data$Phylum)
ph_1000 <- ph_df[which(ph_df < 1000)]

cl_df <- table(tax_data$Class)
cl_1000 <- cl_df[which(cl_df < 1000)]

or_df <- table(tax_data$Order)
or_1000 <- or_df[which(or_df < 1000)]

## Initialize Groups
tax_data$Group <- NA

# Kingdom < 1000
for (i in 1:length(ki_1000)) {
  tax_data$Group[which(tax_data$Kingdom == names(ki_1000))] <- names(ki_1000)
}
# Phylum < 1000
for (i in 1:length(ph_1000)) {
  tax_data$Group[which(tax_data$Phylum == names(ph_1000)[i] & is.na(tax_data$Group))] <- names(ph_1000)[i]
}
# Class < 1000
for (i in 1:length(cl_1000)) {
  tax_data$Group[which(tax_data$Class == names(cl_1000)[i] & is.na(tax_data$Group))] <- names(cl_1000)[i]
}
# Order < 1000
for (i in 1:length(or_1000)) {
  tax_data$Group[which(tax_data$Order == names(or_1000)[i] & is.na(tax_data$Group))] <- names(or_1000)[i]
}
# Remainder by Family
tax_data$Group[which(is.na(tax_data$Group))] <- tax_data$Family[which(is.na(tax_data$Group))]

## Writing to files
for (row in 1:nrow(tax_data)) {
  filename <- paste(tax_data[row,]$Group, "hashlist.txt", sep = "_")
  filepath <- paste(paste(file_path_as_absolute("./data/minhash/hashlists"), "/", sep = ""), filename, sep = "")
  hashpath <- paste(paste(paste(file_path_as_absolute("./data/minhash"), "kmc_", sep="/"), tax_data[row,]$Assembly_Accession, sep = ""), "minhash.jac", sep = ".")
  write(hashpath, file = filepath, append = T)
}