# FIGURE 11: Cluster evolution over time (2020-21 to 2025-26)
# Shows how cluster sizes and performance change over time

library(tidyverse)
source("scripts/R/00_functions.R")

cat("CLUSTER EVOLUTION OVER TIME\n\n")

# Read data
df <- read_csv("data/historical/all_seasons_with_clusters.csv", show_col_types = FALSE)

# Standardize team names
team_name_mapping <- c(
  "L.A" = "LAK",
  "N.J" = "NJD",
  "S.J" = "SJS",
  "T.B" = "TBL",
  "ARI" = "UTA"
)

df <- df %>%
  mutate(team = ifelse(team %in% names(team_name_mapping),
                     team_name_mapping[team],
                     team))

# Load cleaned data with performance metrics
df_clean <- read_csv("data/cleaned/all_seasons_clean.csv", show_col_types = FALSE)

# Join cluster assignments with performance metrics
df <- df %>%
  left_join(
    df_clean %>% dplyr::select(team, season_year, output_goals_per60, input_xGoals_per60, output_goals_pct),
    by = c("team", "season_year")
  )

# Cluster names
cluster_names_map <- c(
  "1" = "Crash & Hope",
  "2" = "High-Octane Drive",
  "3" = "Streaky Offense",
  "4" = "Selective Shooting",
  "5" = "Lane Creation",
  "6" = "Puck Hog & Finish"
)

cat("Data:", nrow(df), "team-seasons\n\n")

# Season order
season_order <- c("2020-2021", "2021-2022", "2022-2023", "2023-2024", "2024-2025", "2025-2026")

# Cluster colors
cluster_colors <- c(
  "1" = "#e74c3c", "2" = "#3498db", "3" = "#27ae60",
  "4" = "#9b59b6", "5" = "#f39c12", "6" = "#1abc9c"
)

# GRAPH 1: NUMBER OF TEAMS PER CLUSTER
cat("Creating: Number of teams per cluster...\n")

cluster_counts <- df %>%
  group_by(season_year, cluster) %>%
  summarise(n = n(), .groups = "drop") %>%
  mutate(
    cluster_name = cluster_names_map[as.character(cluster)],
    cluster = factor(cluster)
  ) %>%
  mutate(season_year = factor(season_year, levels = season_order))

p_count <- ggplot(cluster_counts, aes(x = season_year, y = n, color = cluster, group = cluster)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3.5) +
  scale_color_manual(
    values = cluster_colors,
    labels = cluster_names_map[names(cluster_colors)]
  ) +
  labs(
    title = "Cluster Size Over Time",
    subtitle = "Number of teams per offensive style (2020-21 to 2025-26)",
    x = NULL,
    y = "Number of Teams",
    color = NULL
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    axis.text.x = element_text(size = 11, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 11),
    legend.position = "right",
    legend.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold")
  )

# GRAPH 2: GOALS/60 PER CLUSTER OVER TIME
cat("Creating: Goals/60 per cluster...\n")

goals_by_cluster <- df %>%
  group_by(season_year, cluster) %>%
  summarise(
    goals_per60 = mean(output_goals_per60, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    cluster_name = cluster_names_map[as.character(cluster)],
    cluster = factor(cluster)
  ) %>%
  filter(!is.na(goals_per60)) %>%
  mutate(season_year = factor(season_year, levels = season_order))

p_goals <- ggplot(goals_by_cluster, aes(x = season_year, y = goals_per60,
                                         color = cluster, group = cluster)) +
  geom_line(linewidth = 1.2) +
  geom_point(aes(size = n), alpha = 0.9) +
  geom_hline(yintercept = mean(df$output_goals_per60, na.rm = TRUE),
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  scale_color_manual(
    values = cluster_colors,
    labels = cluster_names_map[names(cluster_colors)]
  ) +
  scale_size_continuous(
    name = "Teams",
    range = c(2, 6),
    breaks = c(1, 4, 8, 12, 16)
  ) +
  labs(
    title = "Goals/60 by Cluster Over Time",
    subtitle = "Dashed line = league average | Point size = number of teams",
    x = NULL,
    y = "Goals/60 (5v5)",
    color = NULL
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    axis.text.x = element_text(size = 11, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 11),
    legend.position = "right",
    legend.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold")
  )

# COMBINE WITH PATCHWORK
library(patchwork)

p_combined <- p_count / p_goals +
  plot_annotation(
    title = "Offensive Archetypes: Evolution Over Time",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5)
    )
  )

# Save
ggsave("outputs/figures/figure8_cluster_evolution.png", p_combined,
       width = 11, height = 12, dpi = 150)

cat("Saved: outputs/figures/figure8_cluster_evolution.png\n")
print(p_combined)

# SUMMARY TABLE
cat("\nSTATISTICAL SUMMARY\n\n")

summary_table <- df %>%
  group_by(season_year, cluster) %>%
  summarise(
    n_teams = n(),
    avg_goals_per60 = mean(output_goals_per60, na.rm = TRUE),
    sd_goals_per60 = sd(output_goals_per60, na.rm = TRUE),
    avg_xGoals_per60 = mean(input_xGoals_per60, na.rm = TRUE),
    avg_gf_pct = mean(output_goals_pct, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    cluster_name = cluster_names_map[as.character(cluster)],
    cluster = as.integer(as.character(cluster))
  ) %>%
  arrange(season_year, cluster) %>%
  dplyr::select(season_year, cluster, cluster_name, everything())

print(summary_table %>% mutate(across(where(is.numeric), ~round(., 2))))

write_csv(summary_table, "outputs/tables/historical_summary_by_cluster_season.csv")
cat("\nFile saved:\n")
cat("  outputs/tables/historical_summary_by_cluster_season.csv\n")
