# ==============================================================================
# 03a_explore_dimensions.R
# Exploration descriptive des 32 équipes NHL à travers 6 dimensions FA
# ==============================================================================

# Load libraries ---------------------------------------------------------------
library(tidyverse)
library(clessnize)

# Check if ggrepel is available
has_ggrepel <- requireNamespace("ggrepel", quietly = TRUE)
if (has_ggrepel) {
  library(ggrepel)
}

# Read data --------------------------------------------------------------------
data <- read_csv("data/processed/team_dimension_scores.csv",
                 show_col_types = FALSE)

# Create output directory ------------------------------------------------------
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Prepare data for plotting ----------------------------------------------------
# Get dimension columns (all except team and name)
dim_cols <- setdiff(names(data), c("team", "name"))

# For heatmap: pivot longer and order teams by Volume
data_long <- data %>%
  arrange(Volume) %>%  # Sort by Volume for sensible ordering
  mutate(team = factor(team, levels = team)) %>%  # Lock in order
  pivot_longer(cols = all_of(dim_cols),
               names_to = "dimension",
               values_to = "score")

# For parallel coordinates: same data but keep wide format for line plotting
data_parallel <- data %>%
  pivot_longer(cols = all_of(dim_cols),
               names_to = "dimension",
               values_to = "score") %>%
  mutate(dimension = factor(dimension, levels = dim_cols))

# Summary: Find extreme teams per dimension -----------------------------------
cat("\n=== Équipes extrêmes par dimension ===\n\n")
for (dim in dim_cols) {
  max_team <- data %>% slice_max(!!sym(dim), n = 1)
  min_team <- data %>% slice_min(!!sym(dim), n = 1)

  cat(sprintf("%s:\n", dim))
  cat(sprintf("  Max: %s (%.2f)\n", max_team$team, max_team[[dim]]))
  cat(sprintf("  Min: %s (%.2f)\n", min_team$team, min_team[[dim]]))
  cat("\n")
}

# PLOT 1: Heatmap --------------------------------------------------------------
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
    title = "Profil offensif des équipes par dimension (z-scores)",
    x = NULL,
    y = NULL
  ) +
  theme_clean_light() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 9),
    panel.grid = element_blank(),
    legend.position = "right"
  )

# Save heatmap
ggsave("outputs/figures/03_dimensions_heatmap.png",
       plot = p1,
       width = 9,
       height = 12,
       dpi = 150)

cat("Saved: outputs/figures/explore_dim_heatmap.png\n")

# PLOT 2: Parallel coordinates -------------------------------------------------
cat("Creating parallel coordinates plot...\n")

# Identify extreme teams (abs(score) > 2 in any dimension)
extreme_teams <- data %>%
  pivot_longer(cols = all_of(dim_cols), names_to = "dim", values_to = "val") %>%
  filter(abs(val) > 2) %>%
  pull(team) %>%
  unique()

# Get last dimension position for each extreme team (for labeling)
label_data <- data_parallel %>%
  filter(team %in% extreme_teams, dimension == last(levels(dimension)))

# Create plot
p2 <- ggplot(data_parallel, aes(x = dimension, y = score, group = team)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_line(aes(color = data$Volume[match(team, data$team)]),
            alpha = 0.7, linewidth = 0.8) +
  geom_point(aes(color = data$Volume[match(team, data$team)]),
             size = 1.5, alpha = 0.7) +
  scale_color_gradient2(
    low = "#2166ac",
    mid = "white",
    high = "#b2182b",
    midpoint = 0,
    name = "Volume\n(z-score)"
  ) +
  labs(
    title = "Coordonnées parallèles des profils offensifs",
    x = NULL,
    y = "Score (z-score)"
  ) +
  theme_clean_light() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.x = element_blank(),
    legend.position = "right"
  )

# Add labels for extreme teams
if (has_ggrepel) {
  p2 <- p2 +
    geom_text_repel(
      data = label_data,
      aes(label = team),
      size = 3,
      nudge_x = 0.3,
      segment.size = 0.3,
      segment.color = "gray50",
      direction = "y",
      hjust = 0
    )
} else {
  # Fallback to geom_text if ggrepel not available
  p2 <- p2 +
    geom_text(
      data = label_data,
      aes(label = team),
      size = 3,
      nudge_x = 0.2,
      hjust = 0
    )
}

# Save parallel coordinates
ggsave("outputs/figures/03_dimensions_parallel.png",
       plot = p2,
       width = 11,
       height = 7,
       dpi = 150)

cat("Saved: outputs/figures/explore_dim_parallel.png\n")

# Print summary ----------------------------------------------------------------
cat("\n=== Script complete ===\n")
cat("Output files:\n")
cat("  - /home/hubcad25/code/hockey/how_teams_create_off/outputs/figures/explore_dim_heatmap.png\n")
cat("  - /home/hubcad25/code/hockey/how_teams_create_off/outputs/figures/explore_dim_parallel.png\n")
