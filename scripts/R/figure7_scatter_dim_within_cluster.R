# FIGURE 7: Dimension scores vs Goals/60 by cluster
# Facet grid: cluster × dimension, with lm trend lines

library(tidyverse)
source("scripts/R/00_functions.R")

# Read data
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE) %>%
  mutate(cluster = factor(cluster))

df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

df <- df_teams %>%
  left_join(df_metrics %>% select(team, output_goals_per60), by = "team")

# Pivot dimensions to long format
dimension_cols <- c("Volume", "Qualite", "Penetration", "Rebonds",
                    "Finishing", "RecoveryPossession", "PuckExchanges")

dimension_labels <- c(
  "Volume"             = "Volume",
  "Qualite"            = "Quality",
  "Penetration"        = "Penetration",
  "Rebonds"            = "Rebounds",
  "RecoveryPossession" = "Recovery+Possession",
  "PuckExchanges"      = "Puck Exchanges",
  "Finishing"          = "Finishing"
)

# Order clusters by mean GF/60 (descending)
cluster_gf_order <- df %>%
  group_by(cluster) %>%
  summarise(mean_gf = mean(output_goals_per60), .groups = "drop") %>%
  arrange(desc(mean_gf)) %>%
  mutate(label = cluster_names[as.character(cluster)]) %>%
  pull(label)

df_long <- df %>%
  pivot_longer(cols = all_of(dimension_cols),
               names_to = "dimension",
               values_to = "score") %>%
  mutate(
    dimension = factor(dimension_labels[dimension],
                       levels = dimension_labels),
    cluster_name = factor(cluster_names[as.character(cluster)],
                          levels = cluster_gf_order)
  )

# CREATE PLOT
cat("Creating dimension vs GF/60 scatter grid...\n")

p <- ggplot(df_long, aes(x = score, y = output_goals_per60, color = cluster)) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.6) +
  geom_point(size = 1.8, alpha = 0.85) +
  scale_color_manual(values = cluster_colors, labels = cluster_names) +
  facet_grid(cluster_name ~ dimension, scales = "free_x", switch = "y") +
  labs(
    title = "Dimension Scores vs Goals/60 by Archetype",
    subtitle = "Dashed line = linear trend within archetype",
    x = "Dimension score (z)",
    y = NULL,
    color = NULL
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    strip.text.x = element_text(size = 9),
    strip.text.y.left = element_text(size = 9, angle = 0, hjust = 1),
    strip.placement = "outside",
    legend.position = "none",
    panel.spacing = unit(0.4, "lines")
  )

# Save
ggsave("outputs/figures/figure7_scatter_dim_within_cluster.png", p,
       width = 13, height = 9, dpi = 300)

cat("Saved: outputs/figures/figure7_scatter_dim_within_cluster\n")
print(p)
