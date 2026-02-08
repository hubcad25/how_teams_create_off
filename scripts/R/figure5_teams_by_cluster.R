# FIGURE 7: Team profiles by cluster (horizontal)
# Shows each team's dimension scores, grouped by cluster

library(tidyverse)
source("scripts/R/00_functions.R")
library(patchwork)

# Read data
profiles <- read_csv("outputs/tables/cluster_profiles.csv", show_col_types = FALSE)
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE)
df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE) %>%
  select(team, output_goals_per60)

score_cols <- c("Volume", "Qualite", "Penetration", "Rebonds",
                "RecoveryPossession", "PuckExchanges")

# Prepare data
radar_data <- profiles %>%
  select(cluster, all_of(score_cols)) %>%
  pivot_longer(cols = all_of(score_cols),
               names_to = "dimension",
               values_to = "score") %>%
  mutate(
    cluster = as.integer(cluster),
    dimension = factor(dimension, levels = score_cols)
  ) %>%
  arrange(cluster, dimension)

# Add facet label and order by GF/60 mean
facet_labels <- df_teams %>%
  left_join(df_metrics, by = "team") %>%
  arrange(cluster, team) %>%
  group_by(cluster) %>%
  summarise(
    teams_str = paste(head(team, 4), collapse = ", "),
    n = n(),
    gf60_mean = mean(output_goals_per60, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    teams_str = ifelse(n > 4, paste0(teams_str, ", ..."), teams_str),
    cluster_name = cluster_names[as.character(cluster)],
    label = paste0(cluster_name, " (", teams_str, ")")
  ) %>%
  arrange(desc(gf60_mean)) %>%
  mutate(label = factor(label, levels = label))

radar_data <- radar_data %>%
  left_join(facet_labels %>% select(cluster, label), by = "cluster")

# CREATE FACETS
create_profile_facet <- function(focal_cl) {

  # Identify focal cluster
  focal_cluster_id <- radar_data %>%
    filter(label == focal_cl) %>%
    pull(cluster) %>%
    unique()

  focal_color <- cluster_colors[focal_cluster_id]

  # Background data (other clusters)
  bg_data <- radar_data %>%
    filter(cluster != focal_cluster_id)

  # Focal data
  focal_data <- radar_data %>%
    filter(cluster == focal_cluster_id)

  # Create plot
  p <- ggplot() +
    geom_hline(yintercept = 0, color = "grey80", linewidth = 0.5) +

    # Background segments
    geom_segment(
      data = bg_data,
      aes(x = dimension, y = 0, xend = dimension, yend = score, group = cluster),
      inherit.aes = FALSE,
      color = "grey70", linewidth = 2, alpha = 0.2
    ) +

    # Focal segments
    geom_segment(
      data = focal_data,
      aes(x = dimension, y = 0, xend = dimension, yend = score),
      inherit.aes = FALSE,
      color = focal_color, linewidth = 3.5, alpha = 0.4
    ) +

    # Background points
    geom_point(
      data = bg_data,
      aes(x = dimension, y = score, group = cluster),
      inherit.aes = FALSE,
      color = "grey60", size = 1.2, alpha = 0.3
    ) +

    # Focal points (large transparent)
    geom_point(
      data = focal_data,
      aes(x = dimension, y = score),
      inherit.aes = FALSE,
      color = focal_color, size = 8, alpha = 0.5, shape = 16
    ) +

    # Focal points (small solid center)
    geom_point(
      data = focal_data,
      aes(x = dimension, y = score),
      inherit.aes = FALSE,
      color = focal_color, size = 2.5, alpha = 0.9, shape = 16
    ) +

    scale_y_continuous(
      limits = c(-3.5, 3.5),
      breaks = seq(-3, 3, by = 1)
    ) +

    theme_hockey() +
    theme(
      axis.title = element_blank(),
      axis.text.x = element_text(size = 8, face = "bold", color = "grey20", angle = 45, hjust = 1),
      axis.text.y = element_text(size = 7, color = "grey50"),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
      panel.border = element_blank(),
      strip.text = element_text(size = 9, face = "plain"),
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 5, 5, 5)
    ) +
    labs(title = focal_cl)

  return(p)
}

# GENERATE ALL PLOTS
all_labels <- levels(radar_data$label)
all_plots <- map(all_labels, create_profile_facet)

nrow <- 2

profile_combined <- wrap_plots(all_plots, nrow = nrow) +
  plot_annotation(
    title = "Team Offensive Profiles by Cluster",
    subtitle = "Focal cluster highlighted in color, others in gray | Clusters ordered by mean GF/60",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 11, color = "grey40", hjust = 0.5)
    )
  )

# Save
ggsave("outputs/figures/figure5_teams_by_cluster.png", profile_combined,
       width = 12, height = 14, dpi = 150)

cat("Saved: outputs/figures/figure5_teams_by_cluster.png\n")
print(profile_combined)
