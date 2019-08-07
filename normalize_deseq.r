#!/usr/bin/env Rscript

args <- commandArgs(TRUE)

filename   <- args[1]          # data matrix file name
ofilename  <- args[2]          # output file name: normalized
factorname <- args[3]          # output file name: factor size


#options(digits=3)


##### if use deseq2, counts(dds, normalized=T)

library(DESeq)

data <- read.delim(filename, header=TRUE, row.names=1, check.names=FALSE)
conds <- factor( c(1:ncol(data)))

cds <- newCountDataSet(data, conds)
cds <- estimateSizeFactors(cds)
pData(cds)
normalizedCounts <- as.data.frame( t( t(counts(cds)) / sizeFactors(cds) ) )

write.table(normalizedCounts, ofilename, sep="\t", quote=FALSE, col.names=NA)
write.table(pData(cds), factorname, sep="\t", quote=FALSE, col.names=NA)


sessionInfo()
