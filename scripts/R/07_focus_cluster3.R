# All Clusters: Relationship between Finishing and GF/60

library(tidyverse)
library(clessnize)
library(ggrepel)

# 1. CHARGEMENT ----

df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE)
df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE) %>%
  select(team, output_goals_per60)

# 2. PRÉPARATION DES DONNÉES ----

# Joindre les données
all_data <- df_teams %>%
  select(team, name, cluster, Finishing) %>%
  left_join(df_metrics, by = "team")

# Ajouter noms des clusters et ordonner par GF/60 moyen
cluster_names <- c(
  "1" = "Crash & Hope",
  "2" = "High-Octane Drive",
  "3" = "Streaky Offense",
  "4" = "Selective Shooting",
  "5" = "Lane Creation",
  "6" = "Puck Hog & Finish"
)

cluster_order <- all_data %>%
  group_by(cluster) %>%
  summarise(gf60_mean = mean(output_goals_per60, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(gf60_mean)) %>%
  pull(cluster) %>%
  as.character()

all_data <- all_data %>%
  mutate(
    cluster_name = cluster_names[as.character(cluster)],
    cluster = factor(cluster, levels = cluster_order)
  )

# Couleurs par cluster
cluster_colors <- c(
  "2" = "#e74c3c",  # High-Octane - red
  "6" = "#3498db",  # Puck Hog - blue
  "4" = "#27ae60",  # Selective - green
  "3" = "#f39c12",  # Streaky - orange
  "1" = "#9b59b6",  # Balanced - purple
  "5" = "#1abc9c"   # Possession - teal
)

# 3. SCATTER PLOT ----

p <- ggplot(all_data, aes(x = Finishing, y = output_goals_per60)) +
  # Ligne de référence à zéro
  geom_vline(xintercept = 0, color = "grey70", linewidth = 0.4, linetype = "dashed") +

  # Facets par cluster
  facet_wrap(~ cluster, ncol = 3, labeller = labeller(cluster = cluster_names)) +

  # Points colorés par cluster
  geom_point(aes(color = cluster), size = 3, alpha = 0.7, shape = 16, show.legend = FALSE) +

  # Labels des équipes
  geom_text_repel(aes(label = name),
                  size = 2.8, fontface = "bold", color = "grey30",
                  max.overlaps = 15, segment.color = "grey70") +

  # Échelles
  scale_x_continuous(
    limits = c(-3.2, 2.0),
    breaks = seq(-3, 2, by = 1)
  ) +
  scale_y_continuous(
    limits = c(1.8, 3.6),
    breaks = seq(1.8, 3.6, by = 0.3)
  ) +
  scale_color_manual(values = cluster_colors) +

  theme_clean_light() +
  theme(
    axis.title = element_text(size = 10, face = "bold"),
    axis.text = element_text(size = 8),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    panel.border = element_rect(color = "grey70", fill = NA, linewidth = 0.4),
    strip.text = element_text(size = 9, face = "bold"),
    strip.background = element_rect(fill = "grey95", color = "grey70"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey40")
  ) +
  labs(
    title = "Finishing vs Goals For/60 by Cluster",
    subtitle = "How finishing ability drives offensive production across different offensive styles",
    x = "Finishing Score (z-score)",
    y = "Goals For / 60"
  )

# 4. SAUVEGARDER ----

ggsave("outputs/figures/07_cluster3_finishing.png", p,
       width = 12, height = 8, dpi = 150)

print(p)
cat("\nSauvegardé: outputs/figures/all_clusters_finishing_gf60.png\n")
