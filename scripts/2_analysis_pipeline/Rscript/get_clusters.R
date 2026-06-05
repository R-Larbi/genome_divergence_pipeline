## Script to attribute clustering level to each species
## Takes a taxonomy dataset of all the studied species and writes lists of absolute 
## paths to their hashed distance files clustered by clades of less than 1000 members

library(tools)
library(stringr)

args = commandArgs(trailingOnly=TRUE)

# Test if there is an argument: if not, return an error
if (length(args) < 3) {
  stop("Rscript error: three arguments must be supplied (taxonomy dataset, accession list and output path to phylum list)", call.=FALSE)
} else if (length(args) > 3) {
  stop("Rscript error: too many arguments detected, must only be three (taxonomy dataset, accession list and output path to phylum list)", call.=FALSE)
}

tax_data <- read.table(args[1], sep="\t", header=T)   # Taxonomy data
acc_data <- scan(args[2], what=character(), sep="\n") # List of accession numbers
## Cleaning
for (i in 1:length(acc_data)) {
  acc_data[i] <- str_remove_all(acc_data[i], "kmc_")
  acc_data[i] <- str_remove_all(acc_data[i], ".minhash.jac")
}

## Only keep taxonomy data for the species listed
tax_data <- tax_data[tax_data$Assembly_Accession %in% acc_data,]
## Cleaning
tax_data$Kingdom[which(tax_data$Kingdom == "")] <- "OtherEukaryota"
tax_data$Phylum[which(tax_data$Phylum == "")] <- "NoPhylum"
tax_data$Class[which(tax_data$Class == "")] <- "NoClass"
tax_data$Order[which(tax_data$Order == "")] <- "NoOrder"
tax_data$Family[which(tax_data$Family == "")] <- "NoFamily"

## Getting names of clades with less than 500 members
ki_df <- table(tax_data$Kingdom)
ki_500 <- ki_df[which(ki_df < 500)]

ph_df <- table(tax_data$Phylum)
ph_500 <- ph_df[which(ph_df < 500)]

cl_df <- table(tax_data$Class)
cl_500 <- cl_df[which(cl_df < 500)]

or_df <- table(tax_data$Order)
or_500 <- or_df[which(or_df < 500)]

fa_df <- table(tax_data$Family)
fa_500 <- fa_df[which(fa_df < 500)]

## Initialize Groups
tax_data$Group <- NA

# Kingdom < 500
for (i in 1:length(ki_500)) {
  tax_data$Group[which(tax_data$Kingdom == names(ki_500)[i])] <- names(ki_500)
}
# Phylum < 500
for (i in 1:length(ph_500)) {
  if (length(tax_data[which(tax_data$Phylum==names(ph_500)[i]),]$Assembly_Accession) <= 2){
    tax_data$Group[which(tax_data$Phylum == names(ph_500)[i] & is.na(tax_data$Group))] <- "SmallPhylum"
  } else {
    tax_data$Group[which(tax_data$Phylum == names(ph_500)[i] & is.na(tax_data$Group))] <- names(ph_500)[i]
  }
}
# Class < 500
for (i in 1:length(cl_500)) {
  if (length(tax_data[which(tax_data$Class==names(cl_500)[i]),]$Assembly_Accession) <= 2){
    tax_data$Group[which(tax_data$Class == names(cl_500)[i] & is.na(tax_data$Group))] <- "SmallClass"
  } else {
    tax_data$Group[which(tax_data$Class == names(cl_500)[i] & is.na(tax_data$Group))] <- names(cl_500)[i]
  }
}
# Order < 500
for (i in 1:length(or_500)) {
  if (length(tax_data[which(tax_data$Order==names(or_500)[i]),]$Assembly_Accession) <= 2){
    tax_data$Group[which(tax_data$Order == names(or_500)[i] & is.na(tax_data$Group))] <- "SmallOrder"
  } else {
    tax_data$Group[which(tax_data$Order == names(or_500)[i] & is.na(tax_data$Group))] <- names(or_500)[i]
  }
}
# Family < 500
for (i in 1:length(fa_500)) {
  if (length(tax_data[which(tax_data$Family==names(fa_500)[i]),]$Assembly_Accession) <= 2){
    tax_data$Group[which(tax_data$Family == names(fa_500)[i] & is.na(tax_data$Group))] <- "SmallFamily"
  } else {
    tax_data$Group[which(tax_data$Family == names(fa_500)[i] & is.na(tax_data$Group))] <- names(fa_500)[i]
  }
}

## Checking for genus with more than two species
for (i in 1:length( tax_data$Genus[which( is.na(tax_data$Group) )] )){
  if (length(tax_data[which( tax_data$Genus==tax_data$Genus[which( is.na(tax_data$Group) )][i] ),]$Genus) <= 2) {
    tax_data$Group[which(is.na(tax_data$Group))][i] <- "SmallGenus"
  }
  else {
    tax_data$Group[which(is.na(tax_data$Group))][i] <- tax_data$Genus[which(is.na(tax_data$Group))][i]
  }
}

## Get vector of groups
uniq_groups <- unique(tax_data$Group)

## If the group clade is non-existent, give the lowest determined clade that's also another's group (or Kingdom if no other choice)
for (i in 1:length(tax_data$Assembly_Accession)){
  if (tax_data[i,]$Group %in% c("NoFamily", "NoOrder", "NoClass", "NoPhylum", "OtherEukaryota")){
    if (tax_data[i,]$Family %in% uniq_groups & !(tax_data[i,]$Family == "NoFamily")){
      tax_data[i,]$Group <- tax_data[i,]$Family
    } else if (tax_data[i,]$Order %in% uniq_groups & !(tax_data[i,]$Order == "NoOrder")){
      tax_data[i,]$Group <- tax_data[i,]$Order
    } else if (tax_data[i,]$Class %in% uniq_groups & !(tax_data[i,]$Class == "NoClass")){
      tax_data[i,]$Group <- tax_data[i,]$Class
    } else if (tax_data[i,]$Phylum %in% uniq_groups & !(tax_data[i,]$Phylum == "NoPhylum")){
      tax_data[i,]$Group <- tax_data[i,]$Phylum
    } else {
      tax_data[i,]$Group <- tax_data[i,]$Kingdom
    }
  }
}

## If the group clade has less than 2 members, do the same
for (i in 1:length(tax_data$Assembly_Accession)){
  if (tax_data[i,]$Group %in% c("SmallGenus", "SmallFamily", "SmallOrder", "SmallClass", "SmallPhylum")){
    if (tax_data[i,]$Family %in% uniq_groups & length(tax_data[which(tax_data$Family == tax_data[i,]$Family),]) > 2){
      tax_data[i,]$Group <- tax_data[i,]$Family
    } else if (tax_data[i,]$Order %in% uniq_groups & length(tax_data[which(tax_data$Order == tax_data[i,]$Order),]) > 2){
      tax_data[i,]$Group <- tax_data[i,]$Order
    } else if (tax_data[i,]$Class %in% uniq_groups & length(tax_data[which(tax_data$Class == tax_data[i,]$Class),]) > 2){
      tax_data[i,]$Group <- tax_data[i,]$Class
    } else if (tax_data[i,]$Phylum %in% uniq_groups & length(tax_data[which(tax_data$Phylum == tax_data[i,]$Phylum),]) > 2){
      tax_data[i,]$Group <- tax_data[i,]$Phylum
    } else {
      tax_data[i,]$Group <- tax_data[i,]$Kingdom
    }
  }
}

## Writing to files
for (row in 1:nrow(tax_data)) {
  filename <- paste(tax_data[row,]$Group, "hashlist.txt", sep = "_")
  filepath <- paste(paste(file_path_as_absolute("./data/minhash/hashlists"), "/", sep = ""), filename, sep = "")
  hashpath <- paste(paste(paste(file_path_as_absolute("./data/minhash"), "kmc_", sep="/"), tax_data[row,]$Assembly_Accession, sep = ""), "minhash.jac", sep = ".")
  write(hashpath, file = filepath, append = T)
}

phylpath <- args[3]
if (file.exists(phylpath)){
  file.remove(phylpath)
}

for (phyl in 1:length(unique(tax_data$Phylum))){
  for (species in 1:length(tax_data[which(tax_data$Phylum==unique(tax_data$Phylum)[phyl]),]$Assembly_Accession)) {
    phyltext <- paste(unique(tax_data$Phylum)[phyl], tax_data[which(tax_data$Phylum==unique(tax_data$Phylum)[phyl]),]$Assembly_Accession[species], sep = "\t")
    fulltext <- paste(phyltext, tax_data[which(tax_data$Phylum==unique(tax_data$Phylum)[phyl]),]$Group[species], sep = "\t")
    write(fulltext, file=phylpath, append = T)
  }
}
