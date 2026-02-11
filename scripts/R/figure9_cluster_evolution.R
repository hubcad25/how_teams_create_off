# FIGURE 9: Cluster evolution over time (2020-21 to 2025-26)
# Graph 1: Stacked area (proportion) of cluster sizes
# Graph 2: Goals/60 per cluster over time

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

# Current season data (2025-26) from processed file
df_current <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE) %>%
  mutate(season_year = "2025-2026") %>%
  dplyr::select(team, season_year, output_goals_per60, input_xGoals_per60, output_goals_pct)

df <- df %>%
  left_join(
    bind_rows(
      df_clean %>% dplyr::select(team, season_year, output_goals_per60, input_xGoals_per60, output_goals_pct),
      df_current
    ),
    by = c("team", "season_year")
  )

cat("Data:", nrow(df), "team-seasons\n\n")

# Season order + short labels
season_order <- c("2020-2021", "2021-2022", "2022-2023", "2023-2024", "2024-2025", "2025-2026")
season_short <- c("20-21", "21-22", "22-23", "23-24", "24-25", "25-26")

# ── GRAPH 1: STACKED AREA (PROPORTION) ──
cat("Creating: Cluster proportion area plot...\n")

cluster_counts <- df %>%
  group_by(season_year, cluster) %>%
  summarise(n = n(), .groups = "drop") %>%
  complete(season_year = season_order, cluster, fill = list(n = 0)) %>%
  group_by(season_year) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup() %>%
  mutate(
    cluster = factor(cluster),
    season_num = match(season_year, season_order)
  )

# Label positions: midpoint of each stacked segment
label_pos <- cluster_counts %>%
  arrange(season_num, desc(cluster)) %>%
  group_by(season_num) %>%
  mutate(
    ymax = cumsum(prop),
    ymin = lag(ymax, default = 0),
    ymid = (ymin + ymax) / 2
  ) %>%
  ungroup() %>%
  filter(n > 0)

p_area <- ggplot(cluster_counts,
                 aes(x = season_num, y = prop, fill = cluster, group = cluster)) +
  geom_area(alpha = 0.5, color = NA, linewidth = 0.3) +
  geom_text(data = label_pos %>%
              mutate(nudge = case_when(
                season_num == 1 ~ 0.2,
                season_num == max(season_num) ~ -0.2,
                TRUE ~ 0
              )),
            aes(x = season_num + nudge, y = ymid, label = n, color = cluster),
            fontface = "bold", size = 3.2, show.legend = FALSE, inherit.aes = FALSE) +
  scale_fill_manual(
    values = cluster_colors,
    labels = cluster_names[names(cluster_colors)]
  ) +
  scale_color_manual(values = cluster_colors) +
  scale_y_continuous(labels = scales::percent_format(), expand = c(0, 0)) +
  scale_x_continuous(breaks = seq_along(season_order), labels = season_short, expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(
    title = "Archetype Distribution Over Time",
    subtitle = "Share of NHL teams per offensive archetype (2020-21 to 2025-26)",
    x = NULL,
    y = NULL,
    fill = NULL
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "bottom",
    plot.margin = margin(5.5, 15, 5.5, 5.5),
    panel.border = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_blank()
  )

ggsave("outputs/figures/figure9a_cluster_proportions.png", p_area,
       width = 10, height = 6, dpi = 300)
cat("Saved: outputs/figures/figure9a_cluster_proportions.png\n")

# ── GRAPH 2: GOALS/60 PER CLUSTER OVER TIME ──
cat("Creating: Goals/60 per cluster...\n")

goals_by_cluster <- df %>%
  group_by(season_year, cluster) %>%
  summarise(
    goals_per60 = mean(output_goals_per60, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    season_num = match(season_year, season_order)
  ) %>%
  filter(!is.na(goals_per60))

# Order facets by mean goals/60 in 2025-26 (descending)
cluster_order <- goals_by_cluster %>%
  filter(season_year == "2025-2026") %>%
  arrange(desc(goals_per60)) %>%
  pull(cluster) %>%
  as.character()

goals_by_cluster <- goals_by_cluster %>%
  mutate(cluster = factor(as.character(cluster), levels = cluster_order))

# Background data: all clusters repeated for each facet
bg_data <- map_dfr(cluster_order, function(cl) {
  goals_by_cluster %>%
    filter(as.character(cluster) != cl) %>%
    mutate(bg_cluster = as.character(cluster),
           cluster = factor(cl, levels = cluster_order)) %>%
    select(cluster, bg_cluster, season_num, goals_per60)
})

league_avg <- mean(df$output_goals_per60, na.rm = TRUE)

# Individual team points for spread
team_points <- df %>%
  filter(!is.na(output_goals_per60)) %>%
  mutate(
    cluster = factor(as.character(cluster), levels = cluster_order),
    season_num = match(season_year, season_order)
  )

# Facet labels = cluster names
facet_labels <- cluster_names
names(facet_labels) <- names(cluster_names)

p_goals <- ggplot(goals_by_cluster, aes(x = season_num, y = goals_per60)) +
  geom_line(data = bg_data, aes(group = bg_cluster),
            color = "grey80", linewidth = 0.4) +
  geom_hline(yintercept = league_avg,
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_jitter(data = team_points, aes(x = season_num, y = output_goals_per60, color = cluster),
              width = 0.12, size = 2, alpha = 0.5, shape = 19, stroke = NA, show.legend = FALSE) +
  geom_line(aes(color = cluster, group = cluster), linewidth = 1) +
  geom_point(aes(color = cluster), size = 2.5, alpha = 0.9) +
  scale_color_manual(values = cluster_colors) +
  scale_x_continuous(breaks = seq_along(season_order), labels = season_short) +
  lemon::facet_rep_wrap(~ cluster, labeller = labeller(cluster = facet_labels), repeat.tick.labels = TRUE) +
  labs(
    title = "Goals/60 by Archetype Over Time",
    subtitle = "Grey lines = other archetypes | Dashed line = league average | Point size = n teams",
    x = NULL,
    y = "Goals/60 (5v5)"
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "none",
    strip.text = element_text(size = 9),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave("outputs/figures/figure9b_cluster_goals_over_time.png", p_goals,
       width = 10, height = 6, dpi = 300)
cat("Saved: outputs/figures/figure9b_cluster_goals_over_time.png\n")

# ── SUMMARY TABLE ──
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
    cluster_name = cluster_names[as.character(cluster)],
    cluster = as.integer(as.character(cluster))
  ) %>%
  arrange(season_year, cluster) %>%
  dplyr::select(season_year, cluster, cluster_name, everything())

print(summary_table %>% mutate(across(where(is.numeric), ~round(., 2))))

write_csv(summary_table, "outputs/tables/historical_summary_by_cluster_season.csv")
cat("\nFile saved:\n")
cat("  outputs/tables/historical_summary_by_cluster_season.csv\n")
