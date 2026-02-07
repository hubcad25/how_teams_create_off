# FIGURE 1: Heatmap of team offensive profiles
# Shows each team's z-scores across 7 dimensions

library(tidyverse)
library(clessnize)

# Read data
data <- read_csv("data/processed/team_dimension_scores.csv",
                 show_col_types = FALSE)

# Create output directory
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Prepare data for plotting
dim_cols <- setdiff(names(data), c("team", "name"))

# Pivot longer and order teams by Volume
data_long <- data %>%
  arrange(Volume) %>%
  mutate(team = factor(team, levels = team)) %>%
  pivot_longer(cols = all_of(dim_cols),
               names_to = "dimension",
               values_to = "score")

# English dimension names
data_long <- data_long %>%
  mutate(
    dimension = case_when(
      dimension == "Qualite" ~ "Quality",
      dimension == "Rebonds" ~ "Rebounds",
      dimension == "RecoveryPossession" ~ "Recovery+Possession",
      dimension == "PuckExchanges" ~ "Puck exchanges",
      TRUE ~ dimension
    ),
    dimension = factor(dimension, levels = c("Volume", "Quality", "Penetration",
                                             "Rebounds", "Finishing",
                                             "Recovery+Possession", "Puck exchanges"))
  )

# Summary: Find extreme teams per dimension
cat("\n=== Extreme teams per dimension ===\n\n")
for (dim in dim_cols) {
  max_team <- data %>% slice_max(!!sym(dim), n = 1)
  min_team <- data %>% slice_min(!!sym(dim), n = 1)

  cat(sprintf("%s:\n", dim))
  cat(sprintf("  Max: %s (%.2f)\n", max_team$team, max_team[[dim]]))
  cat(sprintf("  Min: %s (%.2f)\n", min_team$team, min_team[[dim]]))
  cat("\n")
}

# CREATE HEATMAP
cat("Creating heatmap...\n")

p1 <- ggplot(data_long, aes(x = dimension, y = team, fill = score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.1f", score)),
            size = 3, color = "black") +
  scale_fill_gradient2(
    low = "#2166ac",
    mid = "white",
    high = "#b2182b",
    midpoint = 0,
    name = "Z-score"
  ) +
  labs(
    title = "NHL Team Offensive Profiles by Dimension (2025-26)",
    x = NULL,
    y = NULL
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 9),
    panel.grid = element_blank(),
    legend.position = "right"
  )

# Save
ggsave("outputs/figures/figure1_dimensions_heatmap.png",
       plot = p1,
       width = 9,
       height = 12,
       dpi = 150)

cat("Saved: outputs/figures/figure1_dimensions_heatmap.png\n")
print(p1)
