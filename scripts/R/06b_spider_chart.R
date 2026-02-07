# Spider/Radar Chart: Profil par cluster (cluster focal + autres en gris)

library(tidyverse)
library(clessnize)

# 1. CHARGEMENT ----

profiles <- read_csv("outputs/tables/cluster_profiles.csv", show_col_types = FALSE)
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE)

cluster_colors <- c("#e74c3c", "#3498db", "#27ae60", "#9b59b6",
                    "#f39c12", "#1abc9c", "#e91e63", "#795548")

score_cols <- c("Volume", "Qualite", "Penetration", "Rebonds",
                "Finishing", "RecoveryPossession", "PuckExchanges")
n_dims <- length(score_cols)

# 2. PRÉPARATION DES DONNÉES ----

# Pivoter en format long
radar_data <- profiles %>%
  select(cluster, all_of(score_cols)) %>%
  pivot_longer(cols = all_of(score_cols),
               names_to = "dimension",
               values_to = "score") %>%
  mutate(
    cluster = as.integer(cluster),
    dim_idx = as.integer(match(dimension, score_cols))
  ) %>%
  arrange(cluster, dim_idx)  # Trier PAR dim_idx APRES l'avoir calculé !

# Ajouter label de facette
facet_labels <- df_teams %>%
  arrange(cluster, team) %>%
  group_by(cluster) %>%
  summarise(
    teams_str = paste(head(team, 4), collapse = ", "),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    teams_str = ifelse(n > 4, paste0(teams_str, ", ..."), teams_str),
    label = paste0("Cluster ", cluster, " (", teams_str, ")")
  )

radar_data <- radar_data %>%
  left_join(facet_labels %>% select(cluster, label), by = "cluster")

# Créer une colonne pour savoir si c'est le cluster focal
radar_data <- radar_data %>%
  group_by(label) %>%
  mutate(focal_cluster = max(cluster)) %>%  # Le cluster focal pour cette facette
  ungroup() %>%
  mutate(
    is_focal = (cluster == focal_cluster),
    cluster_f = factor(cluster)
  )

# 3. FERMER LES POLYGONES ----

radar_closed <- radar_data %>%
  arrange(label, cluster, dim_idx) %>%  # TRIER PAR dim_idx PAS ALPHABÉTIQUEMENT !
  group_by(label, cluster) %>%
  group_modify(~ {
    closing <- .x[1, ]
    closing$dim_idx <- n_dims + 1  # Point de fermeture après le dernier
    bind_rows(.x, closing)
  }) %>%
  ungroup()

# 4. CRÉER LES FACETS ----

create_spider_facet <- function(focal_cl) {

  # Identifier le cluster focal
  focal_cluster_id <- radar_data %>%
    filter(label == focal_cl) %>%
    pull(cluster) %>%
    unique()

  focal_color <- cluster_colors[focal_cluster_id]

  # Données de fond (tous les clusters sans filtre sur label)
  bg_data <- radar_closed %>%
    filter(cluster != focal_cluster_id)

  # Données focales
  focal_data <- radar_closed %>%
    filter(label == focal_cl, cluster == focal_cluster_id)

  # Créer le plot
  p <- ggplot() +
    # Polygones de fond (autres clusters en gris)
    geom_polygon(
      data = bg_data,
      aes(x = dim_idx, y = score, group = cluster),
      inherit.aes = FALSE,
      fill = "grey70", color = "grey60", alpha = 0.15, linewidth = 0.3
    ) +
    # Polygone focal
    geom_polygon(
      data = focal_data,
      aes(x = dim_idx, y = score),
      inherit.aes = FALSE,
      fill = focal_color, color = focal_color, alpha = 0.25, linewidth = 1.0
    ) +
    # Points de fond
    geom_point(
      data = radar_data %>% filter(cluster != focal_cluster_id),
      aes(x = dim_idx, y = score, group = cluster),
      inherit.aes = FALSE,
      color = "grey60", size = 1.5, alpha = 0.3
    ) +
    # Points focaux
    geom_point(
      data = radar_data %>% filter(cluster == focal_cluster_id),
      aes(x = dim_idx, y = score),
      inherit.aes = FALSE,
      color = focal_color, size = 2.5, alpha = 0.9
    ) +
    scale_x_continuous(
      breaks = 1:n_dims,
      labels = score_cols,
      limits = c(1, n_dims + 1),
      expand = c(0, 0)
    ) +
    coord_polar(start = -pi/6) +
    theme_clean_light() +
    theme(
      axis.title = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.text.x = element_text(size = 7, face = "bold", color = "grey20"),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      strip.text = element_text(size = 8, face = "bold"),
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 5, 5, 5)
    ) +
    labs(title = focal_cl)

  return(p)
}

# 5. GÉNÉRER TOUS LES PLOTS ----

all_labels <- unique(radar_data$label)
all_plots <- map(all_labels, create_spider_facet)

# Combiner avec patchwork
library(patchwork)

n_plots <- length(all_plots)
ncol <- 3

spider_combined <- wrap_plots(all_plots, ncol = ncol) +
  plot_annotation(
    title = "Profil offensif 5v5 par cluster",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
    )
  )

# ggsave("outputs/figures/cluster_spider.png", spider_combined,
#        width = 14, height = 10, dpi = 150)

print(spider_combined)
cat("\n[SKIPPED] outputs/figures/cluster_spider.png (obsolete, see 06_cluster_profiles.png)\n")

# 6. VERSION SIMPLE (JUSTE DES POINTS) ----

create_spider_simple <- function(focal_cl) {

  # Identifier le cluster focal
  focal_cluster_id <- radar_data %>%
    filter(label == focal_cl) %>%
    pull(cluster) %>%
    unique()

  focal_color <- cluster_colors[focal_cluster_id]

  # Données de fond
  bg_data <- radar_data %>%
    filter(cluster != focal_cluster_id)

  # Données focales
  focal_data <- radar_data %>%
    filter(cluster == focal_cluster_id)

  # Créer le plot simple - juste des points
  p <- ggplot() +
    # Points de fond (autres clusters en gris)
    geom_point(
      data = bg_data,
      aes(x = dim_idx, y = score),
      inherit.aes = FALSE,
      color = "grey50", size = 1.5, alpha = 0.4
    ) +
    # Points focaux
    geom_point(
      data = focal_data,
      aes(x = dim_idx, y = score),
      inherit.aes = FALSE,
      color = focal_color, size = 3, alpha = 0.9
    ) +
    scale_x_continuous(
      breaks = 1:n_dims,
      labels = score_cols,
      limits = c(1, n_dims),
      expand = c(0.15, 0)
    ) +
    coord_polar(start = -pi/6) +
    theme_clean_light() +
    theme(
      axis.title = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.text.x = element_text(size = 7, face = "bold", color = "grey20"),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      strip.text = element_text(size = 8, face = "bold"),
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 5, 5, 5)
    ) +
    labs(title = focal_cl)

  return(p)
}

# Générer les plots simples
all_simple_plots <- map(all_labels, create_spider_simple)

spider_simple <- wrap_plots(all_simple_plots, ncol = ncol) +
  plot_annotation(
    title = "Profil offensif 5v5 par cluster (points seulement)",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
    )
  )

# ggsave("outputs/figures/cluster_spider_simple.png", spider_simple,
#        width = 14, height = 10, dpi = 150)

print(spider_simple)
cat("[SKIPPED] outputs/figures/cluster_spider_simple.png (obsolete)\n")

# 7. VERSION AVEC GEOM_SEGMENT (rayons du centre) ----

create_spider_segments <- function(focal_cl) {

  # Identifier le cluster focal
  focal_cluster_id <- radar_data %>%
    filter(label == focal_cl) %>%
    pull(cluster) %>%
    unique()

  focal_color <- cluster_colors[focal_cluster_id]

  # Données de fond
  bg_data <- radar_data %>%
    filter(cluster != focal_cluster_id)

  # Données focales
  focal_data <- radar_data %>%
    filter(cluster == focal_cluster_id)

  # Créer le plot avec geom_segment
  p <- ggplot() +
    # Segments de fond (autres clusters en gris)
    geom_segment(
      data = bg_data,
      aes(x = 0, y = 0, xend = dim_idx, yend = score, group = cluster),
      inherit.aes = FALSE,
      color = "grey70", linewidth = 0.4, alpha = 0.3
    ) +
    # Segments focaux
    geom_segment(
      data = focal_data,
      aes(x = 0, y = 0, xend = dim_idx, yend = score),
      inherit.aes = FALSE,
      color = focal_color, linewidth = 1.2, alpha = 0.8
    ) +
    # Points de fond
    geom_point(
      data = bg_data,
      aes(x = dim_idx, y = score),
      inherit.aes = FALSE,
      color = "grey50", size = 1.2, alpha = 0.4
    ) +
    # Points focaux
    geom_point(
      data = focal_data,
      aes(x = dim_idx, y = score),
      inherit.aes = FALSE,
      color = focal_color, size = 3, alpha = 0.9
    ) +
    scale_x_continuous(
      breaks = 1:n_dims,
      labels = score_cols,
      limits = c(0, n_dims),
      expand = c(0, 0)
    ) +
    coord_polar(start = -pi/6) +
    theme_clean_light() +
    theme(
      axis.title = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.text.x = element_text(size = 7, face = "bold", color = "grey20"),
      panel.grid = element_blank(),
      panel.border = element_blank(),
      strip.text = element_text(size = 8, face = "bold"),
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      plot.margin = margin(5, 5, 5, 5)
    ) +
    labs(title = focal_cl)

  return(p)
}

# Générer les plots avec segments
all_segment_plots <- map(all_labels, create_spider_segments)

spider_segments <- wrap_plots(all_segment_plots, ncol = ncol) +
  plot_annotation(
    title = "Profil offensif 5v5 par cluster (rayons)",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
    )
  )

# ggsave("outputs/figures/cluster_spider_segments.png", spider_segments,
#        width = 14, height = 10, dpi = 150)

print(spider_segments)
cat("[SKIPPED] outputs/figures/cluster_spider_segments.png (obsolete)\n")
