# FIGURE 12: Team cluster trajectories (2020-21 to 2025-26)
# Heatmap showing each team's cluster assignment over time

library(tidyverse)
library(clessnize)

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

# Cluster names and colors
cluster_names_map <- c(
  "1" = "Crash & Hope",
  "2" = "High-Octane Drive",
  "3" = "Streaky Offense",
  "4" = "Selective Shooting",
  "5" = "Lane Creation",
  "6" = "Puck Hog & Finish"
)

cluster_colors <- c(
  "1" = "#e74c3c", "2" = "#3498db", "3" = "#27ae60",
  "4" = "#9b59b6", "5" = "#f39c12", "6" = "#1abc9c"
)

# PREPARE DATA FOR HEATMAP
heatmap_data <- df %>%
  select(team, season_year, cluster) %>%
  mutate(
    cluster = factor(cluster),
    cluster_num = as.integer(as.character(cluster)),
    season_year = factor(season_year, levels = season_order)
  ) %>%
  arrange(season_year, cluster_num, team)

# Get teams in 2025-26 and their clusters for ordering
teams_2025 <- df %>%
  filter(season_year == "2025-2026") %>%
  mutate(cluster_num = as.integer(as.character(cluster))) %>%
  select(team, cluster_num) %>%
  arrange(cluster_num, team)

# Order teams by their 2025-26 cluster
heatmap_data <- heatmap_data %>%
  mutate(team = factor(team, levels = teams_2025$team)) %>%
  filter(!is.na(cluster))

# CREATE HEATMAP
cat("Creating team trajectories heatmap...\n")

p_heatmap <- ggplot(heatmap_data, aes(x = season_year, y = team, fill = cluster)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_manual(
    values = cluster_colors,
    labels = cluster_names_map[names(cluster_colors)],
    name = "Cluster",
    drop = FALSE
  ) +
  labs(
    title = "Team Cluster Assignments Over Time",
    subtitle = "Teams ordered by 2025-26 cluster | ARI→UTA merged | Rows show cluster stability 2020-2026",
    x = NULL,
    y = NULL
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 11, angle = 45, hjust = 1),
    panel.grid = element_blank(),
    legend.position = "bottom",
    legend.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold")
  )

# Save
ggsave("outputs/figures/figure12_team_trajectories.png", p_heatmap,
       width = 10, height = 16, dpi = 150)

cat("Saved: outputs/figures/figure12_team_trajectories.png\n")
print(p_heatmap)

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
    df %>% filter(season_year == "2025-2026") %>% select(team, cluster),
    by = "team"
  ) %>%
  mutate(cluster_name = cluster_names_map[as.character(cluster)]) %>%
  arrange(cluster) %>%
  select(team, cluster_name)

if (nrow(stable_teams) > 0) {
  cat("Teams that never changed cluster:\n")
  print(stable_teams)
  cat("\n")
}
