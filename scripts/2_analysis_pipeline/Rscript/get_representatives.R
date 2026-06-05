library(ape)
library(phytools)

args = commandArgs(trailingOnly=TRUE)

# Test if there is an argument: if not, return an error
if (length(args) < 2) {
  stop("Rscript error: two arguments must be supplied (distance matrix and output path to representative species)", call.=FALSE)
} else if (length(args) > 2) {
  stop("Rscript error: too many arguments detected, must only be two (distance matrix and output path to representative species)", call.=FALSE)
}

tree <- read.csv(args[1], sep='\t', header = TRUE, row.names = 1)
treedist <- as.dist(tree)
# bionj
tree <- bionj(treedist)
# nj
tree <- nj(treedist)
# output
write.tree(tree, "tree.nwk")


GetClosest_to_midpoint<-function(tree) {
  # Root the tree on its midpoint
  tree2 <- midpoint.root(tree)
  
  NbTips=length(tree$tip.label)
  
  # Plot the tree to get tips coordinates
  plot(tree2)
  pp <- get("last_plot.phylo", envir = .PlotPhyloEnv)
  Tips2Root=pp$xx[1:NbTips]
  
  # Find the tip that is closest to the root
  dMin=min(Tips2Root)
  sel=which(Tips2Root==dMin)[1]
  
  Closest=tree2$tip.label[sel]
  
  # Highlight the corresponding tip in the tree
  points(x = dMin, y = pp$yy[sel], pch=8, col="red")
  
  # Return the tip that is closest to the root
  return(Closest)
}

# Find the species that is closest to the midpoint
rep_spe <- GetClosest_to_midpoint(tree)

write(rep_spe, file=args[2], append=F)
