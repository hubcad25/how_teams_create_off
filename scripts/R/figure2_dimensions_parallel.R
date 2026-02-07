# FIGURE 2: Parallel coordinates plot of team offensive profiles
# Each line is a team, showing their trajectory across dimensions

library(tidyverse)
library(clessnize)

# Check if ggrepel is available
has_ggrepel <- requireNamespace("ggrepel", quietly = TRUE)
if (has_ggrepel) {
  library(ggrepel)
}

# Read data
data <- read_csv("data/processed/team_dimension_scores.csv",
                 show_col_types = FALSE)

# Create output directory
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Prepare data for plotting
dim_cols <- c("Volume", "Qualite", "Penetration", "Rebonds",
              "Finishing", "RecoveryPossession", "PuckExchanges")

# For parallel coordinates: pivot longer
data_parallel <- data %>%
  pivot_longer(cols = all_of(dim_cols),
               names_to = "dimension",
               values_to = "score") %>%
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

# Identify extreme teams (abs(score) > 2 in any dimension)
extreme_teams <- data %>%
  pivot_longer(cols = all_of(dim_cols), names_to = "dim", values_to = "val") %>%
  filter(abs(val) > 2) %>%
  pull(team) %>%
  unique()

# Get last dimension position for each extreme team (for labeling)
label_data <- data_parallel %>%
  filter(team %in% extreme_teams) %>%
  group_by(team) %>%
  slice_max(dimension, n = 1) %>%
  ungroup()

# CREATE PLOT
cat("Creating parallel coordinates plot...\n")

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
    title = "NHL Team Offensive Profiles: Parallel Coordinates",
    subtitle = "Teams colored by Volume dimension | Extreme teams labeled",
    x = NULL,
    y = "Score (z-score)"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
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
  p2 <- p2 +
    geom_text(
      data = label_data,
      aes(label = team),
      size = 3,
      nudge_x = 0.2,
      hjust = 0
    )
}

# Save
ggsave("outputs/figures/figure2_dimensions_parallel.png",
       plot = p2,
       width = 11,
       height = 7,
       dpi = 150)

cat("Saved: outputs/figures/figure2_dimensions_parallel.png\n")
print(p2)
