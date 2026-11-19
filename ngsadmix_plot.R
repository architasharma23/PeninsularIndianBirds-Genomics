library(ggplot2)
library(dplyr)
library(patchwork)
library(reshape2)

setwd("/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/ngsadmix")

pop_data <- read.table("/media/birdlab/bird_hdd3/vishwa/cryptics/angsd/17_snp_thinning/GRTD/pop.info", 
                       header = FALSE, stringsAsFactors = FALSE)
colnames(pop_data) <- c("Sample", "Pop")

df_info <- pop_data
df_info$Short_ID <- df_info$Sample # Using the Sample ID as the short ID

#define logical order for GRTD pop/ssp
pop_levels <- c("rangoonensis", "paradiseus")

df_info$Pop <- factor(df_info$Pop, levels = pop_levels)
df_info$Gradient_Score <- 0 # Initialize column for gradient sorting

#admixture
best_reps_file <- "best_replicate_per_K.tsv"

if (file.exists(best_reps_file)) {
  best_reps_patch <- read.table(best_reps_file, header = TRUE, stringsAsFactors = FALSE)
  q2_file <- best_reps_patch$qopt_file[best_reps_patch$K == 2]
  
  if (length(q2_file) > 0 && file.exists(q2_file[1])) {
    # Read K=2 data
    q2_data <- read.table(q2_file[1], stringsAsFactors = FALSE)
    q2_data$Sample <- pop_data$Sample
    
    #merge with df_info to align data
    q2_merged <- left_join(df_info, q2_data, by = "Sample")
    
    #detect which cluster (V1 or V2) belongs to the first population (left-most)
    pop1_name <- pop_levels[1] # 'rangoonensis'
    pop1_indices <- which(q2_merged$Pop == pop1_name)
    pop1_mean_V1 <- mean(q2_merged$V1[pop1_indices], na.rm = TRUE)
    pop1_mean_V2 <- mean(q2_merged$V2[pop1_indices], na.rm = TRUE)
    
    target_col <- ifelse(pop1_mean_V1 > pop1_mean_V2, "V1", "V2")
    
    #add target proportion to df_info for sorting
    df_info$Gradient_Score <- q2_merged[[target_col]]
    
    #sort dynamically- purest left, admixed in the middle, purest right
    df_info <- df_info %>% arrange(Pop, desc(Gradient_Score))
  } else {
    warning("K=2 .qopt file not found for sorting. sorting alphabetically.")
    df_info <- df_info %>% arrange(Pop, Short_ID)
  }
} else {
  warning("best_replicate_per_K.tsv not found. sorting alphabetically.")
  df_info <- df_info %>% arrange(Pop, Short_ID)
}

#lock in the new sorted order for all downstream K plots
df_info$Short_ID <- factor(df_info$Short_ID, levels = df_info$Short_ID)


#colors matching pca
# rangoonensis = Green, paradiseus = Red
my_colors <- c("#CC0C00", "#84BD00", "#FFCD00", "#5C88DA", "#c46666")

pop_counts <- table(df_info$Pop)[pop_levels]
line_positions <- cumsum(pop_counts)[-length(pop_counts)] + 0.5 
pop_midpoints <- sapply(pop_levels, function(p) mean(which(df_info$Pop == p)))
pop_labels <- pop_levels


#plot
create_admix_plot <- function(K, is_combined = FALSE, is_bottom = FALSE) {
  
  best_reps <- read.table(best_reps_file, header = TRUE, stringsAsFactors = FALSE)
  q_file <- best_reps$qopt_file[best_reps$K == K]
  
  if (length(q_file) == 0 || !file.exists(q_file[1])) {
    stop(paste("File for K =", K, "not found! Check best_replicate_per_K.tsv"))
  }
  
  q_data <- read.table(q_file[1], stringsAsFactors = FALSE)
  
  #assign original sample names to the Q matrix before sorting
  q_data$Sample <- pop_data$Sample
  
  #merge Q matrix with sorted df_info framework
  q_df <- left_join(df_info, q_data, by = "Sample")
  
  #melt for ggplot
  cluster_cols <- paste0("V", 1:K)
  q_melt <- melt(q_df, id.vars = c("Sample", "Short_ID", "Pop", "Gradient_Score"), 
                 measure.vars = cluster_cols,
                 variable.name = "Cluster", value.name = "Proportion")
  
  #margins
  if (!is_combined) {
    plot_margins <- margin(t = 20, r = 40, b = 130, l = 20, unit = "pt")
  } else if (is_bottom) {
    plot_margins <- margin(t = 5, r = 40, b = 130, l = 20, unit = "pt")
  } else {
    plot_margins <- margin(t = 10, r = 40, b = 5, l = 20, unit = "pt")
  }
  
  p <- ggplot(q_melt, aes(x = Short_ID, y = Proportion, fill = Cluster)) +
    geom_bar(stat = "identity", width = 1, color = "white", linewidth = 0.1) + 
    scale_fill_manual(values = my_colors[1:K]) +
    
    #left and right Y-axes
    scale_y_continuous(
      name = "Proportion",
      expand = c(0, 0), 
      breaks = c(0, 0.25, 0.5, 0.75, 1),
      sec.axis = sec_axis(~., breaks = 0.5, labels = paste("K =", K))
    ) +
    coord_cartesian(ylim = c(0, 1), clip = "off") +
    geom_vline(xintercept = line_positions, linetype = "dashed", color = "black", linewidth = 1) + 
    
    theme_minimal() +
    theme(
      legend.position = "none",
      panel.grid = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y.left = element_text(size = 20, face = "bold", margin = margin(r = 15)),
      axis.text.y.left = element_text(size = 16, color = "black"),
      axis.text.y.right = element_text(size = 22, color = "black", face = "bold"),
      axis.ticks.y = element_line(color = "black"),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 0.8),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      plot.margin = plot_margins
    )
  
  if (!is_combined || is_bottom) {
    p <- p + 
      theme(
        axis.text.x = element_text(size = 16, angle = 90, hjust = 1, vjust = 0.5, color = "black")
      ) +
      annotate("text", x = pop_midpoints, y = -0.45, label = pop_labels, 
               size = 6.5, fontface = "bold.italic", color = "black")
  } else {
    p <- p + theme(
      axis.text.x = element_blank(), 
      axis.ticks.x = element_blank()
    )
  }
  
  return(p)
}


print("Generating GRTD NGSadmix plots...")

#single plots
for (K in 2:4) {
  p_single <- create_admix_plot(K, is_combined = FALSE)
  ggsave(paste0("NGSadmix_GRTD_K", K, ".png"), plot = p_single, width = 12, height = 7.5, dpi = 800, bg = "white")
  ggsave(paste0("NGSadmix_GRTD_K", K, ".pdf"), plot = p_single, width = 12, height = 7.5, bg = "white")
}

#combined plot (K=2, 3, 4 stacked)
p2 <- create_admix_plot(2, is_combined = TRUE, is_bottom = FALSE)
p3 <- create_admix_plot(3, is_combined = TRUE, is_bottom = FALSE)
p4 <- create_admix_plot(4, is_combined = TRUE, is_bottom = TRUE)

combined_plot <- (p2 / p3 / p4) + plot_layout(heights = c(1, 1, 1.5))

ggsave("NGSadmix_GRTD_Combined_K2_to_4.png", plot = combined_plot, width = 12, height = 12, dpi = 800, bg = "white")
ggsave("NGSadmix_GRTD_Combined_K2_to_4.pdf", plot = combined_plot, width = 12, height = 12, bg = "white")