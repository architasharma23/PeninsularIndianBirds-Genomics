#   Calculates Dxy from ANGSD 
#   Modified from Joshua Penalba. https://github.com/mfumagalli/ngsPopGen/blob/master/scripts/calcDxy.R   
# RUN THIS IN THIS MANNER !!
###   Rscript DXY.R -p pop1.mafs -q pop2.mafs -t Callable-genome -o outpath 

library(optparse)

option_list = list(
  make_option(c("-p","--popA"), type="character",
              help="Path to uncompressed .mafs file for population A"),
  make_option(c("-q","--popB"), type="character",
              help="Path to uncompressed .mafs file for population B"),
  make_option(c("-t","--totLen"), type="numeric", default=NULL,
              help="Callable genome length (optional)"),
  make_option(c("-o","--outdir"), type="character", default="Dxy_results",
              help="Output directory [default = Dxy_results]")
)

opt = parse_args(OptionParser(option_list=option_list))

if(is.null(opt$popA) || is.null(opt$popB)){
  stop("Both population mafs files must be supplied.")
}

if(grepl("\\.gz$", opt$popA) || grepl("\\.gz$", opt$popB)){
  stop("Please gunzip the mafs files first.")
}

# Create output directory
dir.create(opt$outdir, showWarnings = FALSE, recursive = TRUE)

cat("Reading population A...\n")
popA <- read.table(opt$popA,
                   header=TRUE,
                   sep="\t",
                   stringsAsFactors=FALSE)

cat("Reading population B...\n")
popB <- read.table(opt$popB,
                   header=TRUE,
                   sep="\t",
                   stringsAsFactors=FALSE)

required <- c("chromo","position","knownEM")

if(!all(required %in% names(popA))){
  stop("Population A mafs file is missing required columns.")
}

if(!all(required %in% names(popB))){
  stop("Population B mafs file is missing required columns.")
}

cat("Merging populations...\n")

allfreq <- merge(popA, popB,
                 by=c("chromo","position"))

cat("Shared sites:", nrow(allfreq), "\n")

allfreq <- allfreq[complete.cases(allfreq[,c("knownEM.x","knownEM.y")]), ]

cat("Sites after removing missing values:", nrow(allfreq), "\n")

####################################################
## dXY calculation
####################################################

allfreq$dxy <-
    allfreq$knownEM.x * (1 - allfreq$knownEM.y) +
    allfreq$knownEM.y * (1 - allfreq$knownEM.x)

####################################################
## Write per-site output
####################################################

persite_file <- file.path(opt$outdir, "Dxy_persite.txt")

write.table(
    allfreq[,c("chromo","position","dxy")],
    file=persite_file,
    quote=FALSE,
    row.names=FALSE,
    sep="\t"
)

cat("Created:", persite_file, "\n")

####################################################
## Summary statistics
####################################################

global_dxy  <- sum(allfreq$dxy)
mean_dxy    <- mean(allfreq$dxy)
sd_dxy      <- sd(allfreq$dxy)
median_dxy  <- median(allfreq$dxy)
min_dxy     <- min(allfreq$dxy)
max_dxy     <- max(allfreq$dxy)
quant_dxy   <- quantile(allfreq$dxy)

####################################################
## Print to screen
####################################################

cat("\n=====================================\n")
cat("Shared sites used: ", nrow(allfreq), "\n")
cat("Global dXY:        ", global_dxy, "\n")

if(!is.null(opt$totLen)){
    cat("Genome-wide dXY:   ", global_dxy/opt$totLen, "\n")
}

cat("\nSummary statistics\n")
cat("------------------\n")
cat("Mean dXY:          ", mean_dxy, "\n")
cat("Median dXY:        ", median_dxy, "\n")
cat("SD dXY:            ", sd_dxy, "\n")
cat("Minimum dXY:       ", min_dxy, "\n")
cat("Maximum dXY:       ", max_dxy, "\n\n")

print(quant_dxy)

####################################################
## Save summary to file
####################################################

summary_file <- file.path(opt$outdir, "Dxy_summary.txt")

sink(summary_file)

cat("========== Dxy Summary ==========\n\n")

cat("Shared sites: ", nrow(allfreq), "\n")
cat("Global dXY: ", global_dxy, "\n")

if(!is.null(opt$totLen)){
    cat("Genome-wide dXY: ", global_dxy/opt$totLen, "\n")
}

cat("\n")

cat("Mean: ", mean_dxy, "\n")
cat("Median: ", median_dxy, "\n")
cat("SD: ", sd_dxy, "\n")
cat("Minimum: ", min_dxy, "\n")
cat("Maximum: ", max_dxy, "\n\n")

cat("Quantiles:\n")
print(quant_dxy)

sink()

cat("Created:", summary_file, "\n")

####################################################
## Histogram
####################################################

hist_file <- file.path(opt$outdir, "Dxy_histogram.pdf")

pdf(hist_file, width=7, height=5)

hist(allfreq$dxy,
     breaks=100,
     main="Distribution of per-site dXY",
     xlab="Per-site dXY",
     col="grey80",
     border="grey30")

dev.off()

cat("Created:", hist_file, "\n")

cat("\nCreated all output files inside folder:\n")
cat("  ", normalizePath(opt$outdir), "\n")
cat("  ", basename(persite_file), "\n")
cat("  ", basename(summary_file), "\n")
cat("  ", basename(hist_file), "\n")
