library(tidyverse)
library(ggrepel)

setwd("/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/pcangsd/")

#read population info
#column 1 = sample/ring id, column 2 = ssp
pop <- read.table("/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/pop.info", header = FALSE, stringsAsFactors = FALSE)
colnames(pop) <- c("ind", "subspecies")

#read PCAngsd covariance matrix
cov_mat <- as.matrix(read.table("GRTD_10ind_Angsd_GL_thinned_10kb.cov"))

#calculate eigenvectors and eigenvalues from the covariance matrix
e <- eigen(cov_mat)
eigenval <- e$values
eigenvec <- e$vectors

#format PCA dataframe
pca <- as.data.frame(eigenvec)
# Rename columns to PC1, PC2, etc.
colnames(pca) <- paste0("PC", 1:ncol(pca))

#assign sample ids from the pop file
pca$ind <- pop$ind

#percentage variance explained
pve <- data.frame(
  PC = 1:length(eigenval),
  pve = (eigenval / sum(eigenval)) * 100
)

#merge pca scores with ssp information
pca_scores <- left_join(pca, pop, by = "ind")


#fixed pca axis limits
X_LIMITS <- c(-1, 1)
Y_LIMITS <- c(-1, 1)

#point appearance
POINT_SIZE   <- 8
POINT_STROKE <- 0.8

#label appearance
LABEL_SIZE <- 7

#font sizes
BASE_FONT_SIZE   <- 20
AXIS_TITLE_SIZE  <- 20
AXIS_TEXT_SIZE   <- 18
LEGEND_TEXT_SIZE <- 18
TITLE_SIZE       <- 22

#legend symbols
LEGEND_KEY_SIZE <- 1.2

#output size
FIG_WIDTH  <- 9
FIG_HEIGHT <- 9
FIG_DPI    <- 600

#plot
GRTD <- ggplot() +
  
  geom_point(
    data = pca_scores,
    aes(
      x = PC1,
      y = PC2,
      fill = subspecies
    ),
    shape = 21,
    size = POINT_SIZE,
    colour = "black",
    stroke = POINT_STROKE
  ) +
  
  scale_fill_manual(
    values = c(
      "rangoonensis" = "#84BD00",
      "paradiseus"   = "#CC0C00"
    )
  ) +
  
  labs(
    title = "103627 SNPs",
    x = paste0(
      "PC1 (",
      round(pve$pve[1], 2),
      "%)"
    ),
    y = paste0(
      "PC2 (",
      round(pve$pve[2], 2),
      "%)"
    )
  ) +
  
  coord_equal(
    xlim = X_LIMITS,
    ylim = Y_LIMITS
  ) +
  
  theme_classic(
    base_size = BASE_FONT_SIZE,
    base_family = "Arial"
  ) +
  
  theme_grey(base_size = 14) +
  
  theme(
    
    plot.title =
      element_text(
        hjust = 0.5,
        face = "bold",
        size = TITLE_SIZE
      ),
    
    axis.title =
      element_text(
        size = AXIS_TITLE_SIZE,
        face = "bold"
      ),
    
    axis.text =
      element_text(
        size = AXIS_TEXT_SIZE
      ),
    
    legend.title =
      element_blank(),
    
    legend.text =
      element_text(
        face = "italic",
        size = LEGEND_TEXT_SIZE
      ),
    
    legend.key.size =
      unit(
        LEGEND_KEY_SIZE,
        "cm"
      ),
    
    panel.grid.minor = element_blank()
  )

GRTD

#save
ggsave(
  "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/pcangsd/GRTD_pca_ssp_10kb.pdf",
  GRTD,
  width = FIG_WIDTH,
  height = FIG_HEIGHT
)

ggsave(
  "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/pcangsd/GRTD_pca_ssp_10kb.png",
  GRTD,
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  dpi = FIG_DPI
)


#points+labels
GRTD_labeled <- GRTD + 
  geom_text_repel(
    data = pca_scores,
    aes(
      x = PC1, 
      y = PC2, 
      label = ind
    ),
    size = 4,              
    box.padding = 0.8,     
    point.padding = 0.6,   
    max.overlaps = Inf,    
    show.legend = FALSE
  )

GRTD_labeled

#save
ggsave(
  "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/pcangsd/GRTD_pca_ssp_labeled_10kb.pdf",
  GRTD_labeled,
  width = FIG_WIDTH,
  height = FIG_HEIGHT
)

ggsave(
  "/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/pcangsd/GRTD_pca_ssp_labeled_10kb.png",
  GRTD_labeled,
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  dpi = FIG_DPI
)