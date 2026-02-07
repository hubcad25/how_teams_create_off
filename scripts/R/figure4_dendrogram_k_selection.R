# FIGURE 4: Dendrogram with k=3 to k=7 colored branches
# Shows different possible cluster solutions

library(tidyverse)
library(cluster)
library(dendextend)
library(patchwork)
library(clessnize)

cat("Creating dendrogram k-selection plot...\n")

# Load data
df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)
hc <- readRDS("data/processed/hclust_ward.rds")

score_cols <- setdiff(names(df_dim), c("team", "name"))
scores <- df_dim %>% select(all_of(score_cols)) %>% as.matrix()
rownames(scores) <- df_dim$team

# Calculate silhouette for k=3 to k=7
d <- dist(scores)
k_range <- 3:7

sil_results <- tibble(
  k = k_range,
  silhouette = NA_real_,
  sizes = NA_character_
)

for (i in seq_along(k_range)) {
  k <- k_range[i]
  clusters <- cutree(hc, k = k)
  sil <- silhouette(clusters, d)
  sil_results$silhouette[i] <- mean(sil[, 3])
  sil_results$sizes[i] <- paste(sort(table(clusters)), collapse = "-")
}

# Create colored dendrograms for k=3 to k=7
dend <- as.dendrogram(hc)

cluster_palettes <- list(
  "3" = c("#e74c3c", "#3498db", "#27ae60"),
  "4" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6"),
  "5" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6", "#f39c12"),
  "6" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6", "#f39c12", "#1abc9c"),
  "7" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6", "#f39c12", "#1abc9c", "#e91e63")
)

dendro_plots <- map(3:7, function(k) {
  dend_k <- color_branches(dend, k = k, col = cluster_palettes[[as.character(k)]])
  ggd <- as.ggdend(dend_k)

  sil_val <- sil_results$silhouette[sil_results$k == k]
  sizes <- sil_results$sizes[sil_results$k == k]

  ggplot() +
    geom_segment(data = ggd$segments,
                 aes(x = x, y = y, xend = xend, yend = yend, color = col),
                 linewidth = 1) +
    scale_color_identity() +
    geom_text(data = ggd$labels,
              aes(x = x, y = y, label = label),
              hjust = 0.5, vjust = 1.3, size = 4, fontface = "bold") +
    scale_x_continuous(expand = expansion(add = 0.5)) +
    scale_y_continuous(expand = expansion(mult = c(0.15, 0.05))) +
    labs(title = sprintf("k = %d  (sil = %.3f, sizes: %s)", k, sil_val, sizes)) +
    theme_clean_light() +
    theme(
      plot.title = element_text(face = "bold", size = 10),
      axis.text = element_blank(),
      axis.title = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      plot.margin = margin(2, 5, 2, 5)
    )
})

p_all_k <- wrap_plots(dendro_plots, ncol = 1)

# Save
ggsave("outputs/figures/figure4_dendrogram_k_selection.png", p_all_k,
       width = 14, height = 18, dpi = 150)

cat("Saved: outputs/figures/figure4_dendrogram_k_selection.png\n")
print(p_all_k)
