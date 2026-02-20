# FIGURE 1: Heatmap of team offensive profiles
# Shows each team's z-scores across 7 dimensions

library(tidyverse)
library(ggnewscale)
source("scripts/R/00_functions.R")

# Read data — filter 2025-26 only for display
# (FA model trained on full 191-team-season pool)
data <- read_csv("data/processed/team_dimension_scores.csv",
                 show_col_types = FALSE) %>%
  filter(season == "2025")

# Create output directory
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Prepare data for plotting
dim_cols <- setdiff(names(data), c("team", "name", "season"))

# Pivot longer and order teams by Volume
data_long <- data %>%
  arrange(Volume) %>%
  mutate(team = factor(team, levels = team)) %>%
  pivot_longer(cols = all_of(dim_cols),
               names_to = "dimension",
               values_to = "score")

# English dimension names - Finishing LAST
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
                                             "Rebounds", "Recovery+Possession",
                                             "Puck exchanges", "Finishing"))
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

# Get dimension positions for the separator line
dim_positions <- as.numeric(factor(levels(data_long$dimension), levels = levels(data_long$dimension)))
separator_pos <- max(dim_positions) - 0.5  # line before Finishing

p1 <- ggplot(data_long) +
  # First layer: 6 clustering dimensions (red-blue palette)
  geom_tile(data = filter(data_long, dimension != "Finishing"),
            aes(x = dimension, y = team, fill = score),
            color = NA) +
  scale_fill_gradientn(
    colors = c(
      colorRampPalette(c("#2980b9", "white"))(5),
      colorRampPalette(c("white", "#c0392b"))(5)[-1]
    ),
    values = {
      neg_br <- seq(min(data_long$score), 0, length.out = 5)
      pos_br <- seq(0, max(data_long$score), length.out = 5)
      breaks <- c(neg_br, pos_br[-1])
      scales::rescale(sign(breaks) * abs(breaks)^0.75)
    },
    name = "Z-score"
  ) +
  # New fill scale for Finishing
  new_scale_fill() +
  # Second layer: Finishing (purple-orange palette)
  geom_tile(data = filter(data_long, dimension == "Finishing"),
            aes(x = dimension, y = team, fill = score),
            color = NA) +
  scale_fill_gradientn(
    colors = c(
      colorRampPalette(c("#8e44ad", "white"))(5),
      colorRampPalette(c("white", "#e67e22"))(5)[-1]
    ),
    values = {
      neg_br <- seq(min(data_long$score), 0, length.out = 5)
      pos_br <- seq(0, max(data_long$score), length.out = 5)
      breaks <- c(neg_br, pos_br[-1])
      scales::rescale(sign(breaks) * abs(breaks)^0.75)
    },
    guide = "none"
  ) +
  # Grey separator line
  geom_vline(xintercept = separator_pos, color = "grey40", linewidth = 1.5) +
  geom_text(aes(x = dimension, y = team, label = sprintf("%.1f", score)),
            size = 3, color = "black") +
  scale_x_discrete(position = "top",
                   labels = function(x) str_wrap(gsub("\\+", "+ ", x), width = 10)) +
  guides(x.sec = guide_axis()) +
  labs(
    title = "Offensive Dimension Scores by Team (2025-26)",
    subtitle = "Scores derived from 1-factor analysis per dimension, standardized as z-scores",
    x = NULL,
    y = NULL
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(size = 14),
    axis.text.x.top = element_text(color = "black", angle = 0, hjust = 0.5, vjust = 0, size = 10),
    axis.text.x.bottom = element_text(color = "black", angle = 0, hjust = 0.5, vjust = 1, size = 10),
    axis.text.y = element_text(color = "black", size = 9),
    panel.grid.major.y = element_blank(),
    panel.grid = element_blank(),
    panel.border = element_blank(),
    legend.position = "right"
  )

# Save
ggsave("outputs/figures/figure2_dimensions_heatmap.png",
       plot = p1,
       width = 7,
       height = 7,
       dpi = 150)

cat("Saved: outputs/figures/figure2_dimensions_heatmap.png\n")
print(p1)
