# Visualize historical cluster evolution (2020-21 to 2025-26)

library(tidyverse)
library(clessnize)

cat("VISUALISATIONS HISTORIQUES\n\n")

# 1. CHARGEMENT ----

df <- read_csv("data/historical/all_seasons_with_clusters.csv", show_col_types = FALSE)

# Standardize team names (2020-24 uses different abbreviations)
team_name_mapping <- c(
  "L.A" = "LAK",
  "N.J" = "NJD",
  "S.J" = "SJS",
  "T.B" = "TBL",
  "ARI" = "UTA"  # Arizona → Utah (franchise relocation)
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
    df_clean %>% select(team, season_year, output_goals_per60, input_xGoals_per60, output_goals_pct),
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

cat("Données:", nrow(df), "équipes-saisons\n\n")

# 2. GRAPHIQUE 1: NOMBRE D'ÉQUIPES PAR CLUSTER DANS LE TEMPS ----

cat("Création: Nombre d'équipes par cluster...\n")

# Count teams per cluster per season
cluster_counts <- df %>%
  group_by(season_year, cluster) %>%
  summarise(n = n(), .groups = "drop") %>%
  mutate(
    cluster_name = cluster_names_map[as.character(cluster)],
    cluster = factor(cluster)
  )

# Order seasons chronologically
season_order <- c("2020-2021", "2021-2022", "2022-2023", "2023-2024", "2024-2025", "2025-2026")
cluster_counts <- cluster_counts %>%
  mutate(season_year = factor(season_year, levels = season_order))

cluster_colors <- c(
  "1" = "#e74c3c", "2" = "#3498db", "3" = "#27ae60",
  "4" = "#9b59b6", "5" = "#f39c12", "6" = "#1abc9c"
)

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
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    axis.text.x = element_text(size = 11, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 11),
    legend.position = "right",
    legend.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold")
  )

ggsave("outputs/figures/10_cluster_counts_evolution.png", p_count,
       width = 11, height = 7, dpi = 150)
cat("  outputs/figures/historical_cluster_counts.png\n")

# 3. GRAPHIQUE 2: GOALS/60 PAR CLUSTER DANS LE TEMPS ----

cat("Création: Goals/60 par cluster...\n")

# Calculate mean goals per 60 per cluster per season
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
  filter(!is.na(goals_per60))

goals_by_cluster <- goals_by_cluster %>%
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
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    axis.text.x = element_text(size = 11, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 11),
    legend.position = "right",
    legend.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold")
  )

ggsave("outputs/figures/10_goals_by_cluster_time.png", p_goals,
       width = 11, height = 7, dpi = 150)
cat("  outputs/figures/historical_goals_by_cluster.png\n")

# 4. GRAPHIQUE 3: HEATMAP ÉQUIPE × SAISON ----

cat("Création: Heatmap équipe × saison...\n")

# Pivot to wide format: rows = teams, cols = seasons
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
  filter(!is.na(cluster))  # Remove rows where team didn't exist in that season

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

ggsave("outputs/figures/10_team_trajectories_heatmap.png", p_heatmap,
       width = 10, height = 16, dpi = 150)
cat("  outputs/figures/historical_team_heatmap.png\n")

# 5. TABLEAU RÉSUMÉ ----

cat("\nRÉSUMÉ STATISTIQUE\n\n")

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
  select(season_year, cluster, cluster_name, everything())

print(summary_table %>% mutate(across(where(is.numeric), ~round(., 2))))

write_csv(summary_table, "outputs/tables/historical_summary_by_cluster_season.csv")
cat("\nFichier sauvegardé:\n")
cat("  outputs/tables/historical_summary_by_cluster_season.csv\n")

cat("\nScript terminé.\n")
