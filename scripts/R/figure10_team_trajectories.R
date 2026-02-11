# FIGURE 12: Team cluster trajectories (2020-21 to 2025-26)
# Heatmap showing each team's cluster assignment over time

library(tidyverse)
library(ggh4x)
library(colorspace)
source("scripts/R/00_functions.R")

cat("TEAM TRAJECTORIES OVER TIME\n\n")

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

# Season order
season_order <- c("2020-2021", "2021-2022", "2022-2023", "2023-2024", "2024-2025", "2025-2026")

# Read goals data for facet ordering
df_current <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE) %>%
  mutate(season_year = "2025-2026")

# Order clusters by mean GF/60 in 2025-26 (descending)
cluster_goal_order <- df %>%
  filter(season_year == "2025-2026") %>%
  left_join(df_current %>% dplyr::select(team, output_goals_per60), by = "team") %>%
  group_by(cluster) %>%
  summarise(mean_gf60 = mean(output_goals_per60, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(mean_gf60)) %>%
  pull(cluster) %>%
  as.character()

# Darkened cluster colors for text
cluster_colors_dark <- darken(cluster_colors, amount = 0.3)
names(cluster_colors_dark) <- names(cluster_colors)

# PREPARE DATA FOR HEATMAP
heatmap_data <- df %>%
  dplyr::select(team, season_year, cluster, distance_to_centroid) %>%
  mutate(
    cluster = factor(cluster),
    season_year = factor(season_year, levels = season_order)
  ) %>%
  filter(!is.na(cluster))

# Facet by 2025-26 cluster, order teams alphabetically within each facet
teams_2025 <- df %>%
  filter(season_year == "2025-2026") %>%
  mutate(cluster_2025 = factor(cluster, levels = cluster_goal_order)) %>%
  dplyr::select(team, cluster_2025) %>%
  arrange(cluster_2025, team)

heatmap_data <- heatmap_data %>%
  left_join(teams_2025, by = "team") %>%
  mutate(
    cluster_2025 = factor(cluster_2025, levels = cluster_goal_order),
    team = factor(team, levels = rev(teams_2025$team))
  )

# Facet labels = cluster names
facet_labels <- cluster_names
names(facet_labels) <- names(cluster_names)

# CREATE HEATMAP
cat("Creating team trajectories heatmap...\n")

season_short <- c("20-21", "21-22", "22-23", "23-24", "24-25", "25-26")

# Panel heights proportional to number of teams per facet
# Panel heights in facet order (by goals/60)
teams_per_facet <- heatmap_data %>%
  filter(!is.na(cluster_2025)) %>%
  distinct(cluster_2025, team) %>%
  count(cluster_2025, .drop = FALSE) %>%
  mutate(cluster_2025 = factor(cluster_2025, levels = cluster_goal_order)) %>%
  arrange(cluster_2025)
panel_heights <- teams_per_facet$n

p_heatmap <- ggplot(heatmap_data, aes(x = season_year, y = team, fill = cluster)) +
  geom_tile(color = "white", linewidth = 0.25) +
  geom_text(aes(label = round(distance_to_centroid, 1), color = cluster),
            size = 2.5, fontface = "bold", show.legend = FALSE) +
  scale_fill_manual(
    values = cluster_colors,
    labels = cluster_names[names(cluster_colors)],
    name = NULL,
    drop = FALSE
  ) +
  scale_color_manual(values = cluster_colors_dark) +
  scale_x_discrete(labels = season_short) +
  facet_wrap(~ cluster_2025, ncol = 1, labeller = labeller(cluster_2025 = facet_labels),
             scales = "free_y") +
  force_panelsizes(rows = panel_heights) +
  labs(
    title = "Team Cluster Assignments Over Time",
    subtitle = "Number = distance to cluster centroid (lower = closer fit)",
    x = NULL,
    y = NULL
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    axis.text.y = element_text(size = 9),
    axis.text.x = element_text(size = 10),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.border = element_blank(),
    legend.position = "bottom",
    legend.text = element_text(size = 10),
    strip.text = element_blank()
  ) +
  guides(fill = guide_legend(nrow = 2))

# Save
ggsave("outputs/figures/figure10_team_trajectories.png", p_heatmap,
       width = 6, height = 8, dpi = 300)

cat("Saved: outputs/figures/figure10_team_trajectories.png\n")

# STABILITY ANALYSIS
cat("\nCLUSTER STABILITY ANALYSIS\n\n")

# Count teams that stay in same cluster throughout
stability_summary <- df %>%
  group_by(team) %>%
  filter(n() == 6) %>%  # Only teams with all 6 seasons
  summarise(
    n_clusters = n_distinct(cluster),
    first_cluster = first(cluster),
    last_cluster = last(cluster),
    stable = (n_clusters == 1),
    .groups = "drop"
  )

cat("Teams with all 6 seasons:", sum(df %>%
                                      group_by(team) %>%
                                      summarise(n = n()) %>%
                                      pull(n) == 6), "\n")
cat("Teams that never changed cluster:", sum(stability_summary$stable), "\n")
cat("Teams that changed cluster:", sum(!stability_summary$stable), "\n\n")

# Show most stable teams
stable_teams <- stability_summary %>%
  filter(stable) %>%
  left_join(
    df %>% filter(season_year == "2025-2026") %>% dplyr::select(team, cluster),
    by = "team"
  ) %>%
  mutate(cluster_name = cluster_names[as.character(cluster)]) %>%
  arrange(cluster) %>%
  dplyr::select(team, cluster_name)

if (nrow(stable_teams) > 0) {
  cat("Teams that never changed cluster:\n")
  print(stable_teams)
  cat("\n")
}
