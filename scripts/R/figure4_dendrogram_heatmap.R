# FIGURE 4: Dendrogram (colored by k=6) + heatmap
# Perfectly aligned: shared numeric x-axis

library(tidyverse)
library(dendextend)
library(patchwork)
source("scripts/R/00_functions.R")

cat("Creating dendrogram + heatmap k=6...\n")

# Load data
df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)
hc <- readRDS("data/processed/hclust_ward.rds")

score_cols <- setdiff(names(df_dim), c("team", "name"))

dim_english <- c(
  "Volume" = "Volume",
  "Qualite" = "Quality",
  "Penetration" = "Penetration",
  "Rebonds" = "Rebounds",
  "Finishing" = "Finishing",
  "RecoveryPossession" = "Recovery+\nPossession",
  "PuckExchanges" = "Puck\nexchanges"
)

# Team order from dendrogram
team_order <- hc$labels[hc$order]
n_teams <- length(team_order)

# Shared x limits
x_lim <- c(0.5, n_teams + 0.5)

# --- DENDROGRAM (colored by k=6, grey above cut) ---
dend <- as.dendrogram(hc)

# color_branches assigns colors left-to-right, not by cluster ID
# Reorder colors to match dendrogram branch order
dend_cluster_order <- unique(cutree(hc, k = 6)[hc$order])
dend_colors <- unname(cluster_colors[as.character(dend_cluster_order)])
dend_colored <- color_branches(dend, k = 6, col = dend_colors)
ggd <- as.ggdend(dend_colored)

# Cut height: midpoint between 5th and 6th highest merges
cut_height <- mean(sort(hc$height, decreasing = TRUE)[5:6])

# Grey out segments above the cut
seg <- ggd$segments %>%
  mutate(col = ifelse(y >= cut_height | yend >= cut_height, "grey70", col))

p_dendro <- ggplot() +
  geom_segment(data = seg,
               aes(x = x, y = y, xend = xend, yend = yend, color = col),
               linewidth = 0.8) +
  scale_color_identity() +
  scale_x_continuous(limits = x_lim, expand = c(0, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Ward D2 Dendrogram (k=6)") +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.border = element_blank(),
    plot.margin = margin(5, 5, -5, 5)
  )

# --- Cluster boundaries (where cluster changes in dendrogram order) ---
clusters_in_order <- cutree(hc, k = 6)[hc$order]
cluster_breaks <- which(diff(clusters_in_order) != 0) + 0.5

# --- HEATMAP (aligned by numeric x) ---
dim_long <- df_dim %>%
  pivot_longer(cols = all_of(names(dim_english)), names_to = "dimension", values_to = "score") %>%
  mutate(
    team = factor(team, levels = team_order),
    x_pos = as.numeric(team),
    dimension = dplyr::recode(dimension, !!!dim_english),
    dimension = factor(dimension, levels = dim_english)
  )

p_heat <- ggplot(dim_long, aes(x = x_pos, y = dimension, fill = score)) +
  geom_tile(color = NA, linewidth = 0.4) +
  geom_vline(xintercept = cluster_breaks, color = "grey30", linewidth = 0.6) +
  geom_text(aes(label = sprintf("%.1f", score)), size = 2.3) +
  scale_fill_gradientn(
    colors = c(
      colorRampPalette(c("#2980b9", "white"))(5),
      colorRampPalette(c("white", "#c0392b"))(5)[-1]
    ),
    values = {
      neg_br <- seq(min(dim_long$score), 0, length.out = 5)
      pos_br <- seq(0, max(dim_long$score), length.out = 5)
      breaks <- c(neg_br, pos_br[-1])
      scales::rescale(sign(breaks) * abs(breaks)^0.75)
    },
    name = "Z-score"
  ) +
  scale_x_continuous(
    limits = x_lim, expand = c(0, 0),
    breaks = seq_len(n_teams),
    labels = team_order,
    position = "top",
    sec.axis = dup_axis()
  ) +
  labs(x = NULL, y = NULL) +
  theme_hockey() +
  theme(
    axis.text.x.top = element_text(hjust = 0.5, vjust = -1.5, size = 9),
    axis.text.x.bottom = element_text(hjust = 0.5, vjust = 1.5, size = 9),
    axis.text.y = element_text(size = 9),
    panel.grid = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.border = element_blank(),
    legend.key.height = unit(0.5, "cm"),
    plot.margin = margin(-5, 5, 5, 5)
  )

# --- COMBINE ---
p_combined <- p_dendro / p_heat +
  plot_layout(heights = c(1, 2))

# Save
ggsave("outputs/figures/figure4_dendrogram_heatmap.png", p_combined,
       width = 10, height = 6.5, dpi = 150)

cat("Saved: outputs/figures/figure4_dendrogram_heatmap.png\n")
print(p_combined)
