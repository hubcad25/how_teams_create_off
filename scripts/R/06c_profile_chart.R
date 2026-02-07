# Profile Chart Horizontal: Profil par cluster (cluster focal + autres en gris)

library(tidyverse)
library(clessnize)

# 1. CHARGEMENT ----

profiles <- read_csv("outputs/tables/cluster_profiles.csv", show_col_types = FALSE)
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE)
df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE) %>%
  select(team, output_goals_per60)

cluster_colors <- c("#e74c3c", "#3498db", "#27ae60", "#9b59b6",
                    "#f39c12", "#1abc9c", "#e91e63", "#795548")

score_cols <- c("Volume", "Qualite", "Penetration", "Rebonds",
                "Finishing", "RecoveryPossession", "PuckExchanges")
n_dims <- length(score_cols)

# Cluster names
cluster_names <- c(
  "1" = "Crash & Hope",
  "2" = "High-Octane Drive",
  "3" = "Streaky Offense",
  "4" = "Selective Shooting",
  "5" = "Lane Creation",
  "6" = "Puck Hog & Finish"
)

# 2. PRÉPARATION DES DONNÉES ----

# Pivoter en format long
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

# Ajouter label de facette et ordonner par GF/60 moyen
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

# 3. CRÉER LES FACETS ----

create_profile_facet <- function(focal_cl) {

  # Identifier le cluster focal
  focal_cluster_id <- radar_data %>%
    filter(label == focal_cl) %>%
    pull(cluster) %>%
    unique()

  focal_color <- cluster_colors[focal_cluster_id]

  # Données de fond (autres clusters)
  bg_data <- radar_data %>%
    filter(cluster != focal_cluster_id)

  # Données focales
  focal_data <- radar_data %>%
    filter(cluster == focal_cluster_id)

  # Créer le plot
  p <- ggplot() +
    # Ligne de référence à y=0
    geom_hline(yintercept = 0, color = "grey80", linewidth = 0.5) +

    # Segments de fond (autres clusters en gris)
    geom_segment(
      data = bg_data,
      aes(x = dimension, y = 0, xend = dimension, yend = score, group = cluster),
      inherit.aes = FALSE,
      color = "grey70", linewidth = 2, alpha = 0.2
    ) +
    # Segments focaux
    geom_segment(
      data = focal_data,
      aes(x = dimension, y = 0, xend = dimension, yend = score),
      inherit.aes = FALSE,
      color = focal_color, linewidth = 3.5, alpha = 0.4
    ) +
    # Points de fond (autres clusters)
    geom_point(
      data = bg_data,
      aes(x = dimension, y = score, group = cluster),
      inherit.aes = FALSE,
      color = "grey60", size = 1.2, alpha = 0.3
    ) +
    # Points focaux (grands points transparents)
    geom_point(
      data = focal_data,
      aes(x = dimension, y = score),
      inherit.aes = FALSE,
      color = focal_color, size = 8, alpha = 0.5, shape = 16
    ) +
    # Points focaux (petit point solide au centre)
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

    theme_clean_light() +
    theme(
      axis.title = element_blank(),
      axis.text.x = element_text(size = 8, face = "bold", color = "grey20", angle = 45, hjust = 1),
      axis.text.y = element_text(size = 7, color = "grey50"),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
      panel.border = element_blank(),
      strip.text = element_text(size = 9, face = "bold"),
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 5, 5, 5)
    ) +
    labs(title = focal_cl)

  return(p)
}

# 4. GÉNÉRER TOUS LES PLOTS ----

all_labels <- levels(radar_data$label)
all_plots <- map(all_labels, create_profile_facet)

# Combiner avec patchwork
library(patchwork)

ncol <- 2

profile_combined <- wrap_plots(all_plots, ncol = ncol) +
  plot_annotation(
    title = "Profil offensif 5v5 par cluster",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
    )
  )

ggsave("outputs/figures/06_teams_by_cluster.png", profile_combined,
       width = 12, height = 14, dpi = 150)

print(profile_combined)
cat("\nSauvegardé: outputs/figures/06_teams_by_cluster.png\n")
