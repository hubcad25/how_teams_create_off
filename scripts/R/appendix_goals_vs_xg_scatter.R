# APPENDIX: Goals/60 vs xG/60 scatter by cluster
# Shows actual vs expected goals production

library(tidyverse)
library(clessnize)
library(ggrepel)

# Read data
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE) %>%
  mutate(cluster = factor(cluster))

df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

# Cluster colors
cluster_colors <- c("#e74c3c", "#3498db", "#27ae60", "#9b59b6",
                    "#f39c12", "#1abc9c")

# Join data
df_output <- df_teams %>%
  left_join(df_metrics %>% dplyr::select(team, output_goals_per60, input_xGoals_per60), by = "team")

# CREATE PLOT
cat("Creating goals vs xG scatter plot...\n")

p_goals_xg <- ggplot(df_output, aes(x = input_xGoals_per60, y = output_goals_per60,
                                     color = cluster, label = team)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", alpha = 0.4) +
  geom_point(size = 4, alpha = 0.85) +
  geom_text_repel(size = 3.2, max.overlaps = 32, show.legend = FALSE,
                  seed = 42, min.segment.length = 0.3) +
  scale_color_manual(values = cluster_colors[1:6]) +
  labs(
    title = "5v5 Offense: Actual vs Expected Goals",
    subtitle = "2025-26 Season | Above diagonal = outperforming expectations",
    x = "xG/60",
    y = "Goals/60",
    color = "Cluster"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40")
  )

# Save
ggsave("outputs/figures/appendix_goals_vs_xg_scatter.png", p_goals_xg,
       width = 11, height = 8, dpi = 150)

cat("Saved: outputs/figures/appendix_goals_vs_xg_scatter.png\n")
print(p_goals_xg)
