# FIGURE 5: Dendrogram + heatmap with k=6 clusters
# Shows cluster solution with team-by-dimension heatmap

library(tidyverse)
library(cluster)
source("scripts/R/00_functions.R")
library(ggdendro)
library(patchwork)

cat("Creating dendrogram + heatmap k=6...\n")

# Load data
df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)
hc <- readRDS("data/processed/hclust_ward.rds")

score_cols <- setdiff(names(df_dim), c("team", "name"))

# English dimension names
dim_english <- c(
  "Volume" = "Volume",
  "Qualite" = "Quality",
  "Penetration" = "Penetration",
  "Rebonds" = "Rebounds",
  "Finishing" = "Finishing",
  "RecoveryPossession" = "Recovery+Possession",
  "PuckExchanges" = "Puck exchanges"
)

# Team order from dendrogram
team_order <- hc$labels[hc$order]

# CREATE DENDROGRAM
dend_data <- dendro_data(as.dendrogram(hc), type = "rectangle")
leaf_labels <- label(dend_data)

p_dendro <- ggplot() +
  geom_segment(data = segment(dend_data),
               aes(x = x, y = y, xend = xend, yend = yend),
               linewidth = 0.8, color = "#2c3e50") +
  geom_text(data = leaf_labels,
            aes(x = x, y = y, label = label),
            hjust = 0.5, vjust = 1.5, size = 3.8, fontface = "bold") +
  scale_x_continuous(expand = expansion(add = 0.5)) +
  scale_y_continuous(expand = expansion(mult = c(0.12, 0.05))) +
  labs(title = "Dendrogram (Ward D2) with k=6") +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    plot.margin = margin(5, 5, 0, 5)
  )

# CREATE HEATMAP (ordered by dendrogram)
dim_long <- df_dim %>%
  pivot_longer(cols = all_of(names(dim_english)), names_to = "dimension", values_to = "score") %>%
  mutate(
    team = factor(team, levels = team_order),
    dimension = dplyr::recode(dimension, !!!dim_english),
    dimension = factor(dimension, levels = dim_english)
  )

# Symmetric limits based on max absolute value
score_max <- ceiling(max(abs(dim_long$score)) * 10) / 10

p_heat <- ggplot(dim_long, aes(x = as.numeric(team), y = dimension, fill = score)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%.1f", score)), size = 2.3) +
  scale_fill_gradientn(
    colours = c("#08306b", "#2166ac", "#92c5de", "#d1e5f0",
                "white",
                "#fddbc7", "#f4a582", "#b2182b", "#67001f"),
    values = scales::rescale(
      c(-score_max, -score_max*0.75, -score_max*0.45,  -score_max*0.15,
        0,
        score_max*0.15, score_max*0.45, score_max*0.75, score_max),
      to = c(0, 1)
    ),
    limits = c(-score_max, score_max),
    name = "Score"
  ) +
  scale_x_continuous(
    breaks = seq_along(team_order),
    labels = team_order,
    expand = expansion(add = 0.5)
  ) +
  labs(x = NULL, y = NULL) +
  theme_hockey() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 7),
    axis.text.y = element_text(size = 9),
    panel.grid = element_blank(),
    legend.key.height = unit(0.5, "cm"),
    plot.margin = margin(0, 5, 5, 5)
  )

# COMBINE
p_combined <- p_dendro / p_heat +
  plot_layout(heights = c(1, 2))

# Save
ggsave("outputs/figures/figure4_dendrogram_heatmap.png", p_combined,
       width = 14, height = 10, dpi = 150)

cat("Saved: outputs/figures/figure4_dendrogram_heatmap.png\n")
print(p_combined)
