# Cluster 5 Deep Dive: Relationship between all dimensions and GF/60

library(tidyverse)
library(clessnize)
library(ggrepel)

# 1. CHARGEMENT ----

df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE)
df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE) %>%
  select(team, output_goals_per60)

# 2. PRÉPARATION DES DONNÉES ----

# Dimensions à analyser
dimensions <- c("Volume", "Qualite", "Penetration", "Rebonds",
                "Finishing", "RecoveryPossession", "PuckExchanges")

# Joindre les données pour cluster 5
cluster5_data <- df_teams %>%
  filter(cluster == 5) %>%
  select(team, name, all_of(dimensions)) %>%
  left_join(df_metrics, by = "team") %>%
  pivot_longer(cols = all_of(dimensions),
               names_to = "dimension",
               values_to = "score")

# Renommer les dimensions pour l'affichage
dimension_labels <- c(
  "Volume" = "Volume",
  "Qualite" = "Quality",
  "Penetration" = "Penetration",
  "Rebonds" = "Rebounds",
  "Finishing" = "Finishing",
  "RecoveryPossession" = "Recovery+Possession",
  "PuckExchanges" = "Puck Exchanges"
)

cluster5_data <- cluster5_data %>%
  mutate(dimension = dimension_labels[dimension])

# Couleurs pour les 3 équipes
team_colors <- c(
  "EDM" = "#e74c3c",
  "NYR" = "#0038A8",
  "LAK" = "#111111"
)

# 3. SCATTER PLOT ----

p <- ggplot(cluster5_data, aes(x = score, y = output_goals_per60)) +
  # Ligne de référence à zéro
  geom_vline(xintercept = 0, color = "grey70", linewidth = 0.4, linetype = "dashed") +

  # Facets par dimension
  facet_wrap(~ dimension, ncol = 4, scales = "free") +

  # Points colorés par équipe
  geom_point(aes(color = name), size = 4, alpha = 0.8, shape = 16) +

  # Labels des équipes
  geom_text_repel(aes(label = name, color = name),
                  size = 3, fontface = "bold",
                  max.overlaps = 20, segment.color = "grey70",
                  show.legend = FALSE) +

  # Ligne de tendance (optionnelle)
  geom_smooth(method = "lm", se = FALSE, color = "grey50",
              linewidth = 0.5, alpha = 0.5, linetype = "dotted") +

  # Échelles
  scale_y_continuous(
    breaks = seq(2.0, 2.5, by = 0.1),
    expand = expansion(mult = c(0.1, 0.1))
  ) +
  scale_color_manual(values = team_colors) +

  theme_clean_light() +
  theme(
    axis.title = element_text(size = 10, face = "bold"),
    axis.text = element_text(size = 8),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    panel.border = element_rect(color = "grey70", fill = NA, linewidth = 0.4),
    strip.text = element_text(size = 9, face = "bold"),
    strip.background = element_rect(fill = "grey95", color = "grey70"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "grey40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "Cluster 5: Lane Creation - What Drives Offense?",
    subtitle = "Relationship between offensive dimensions and GF/60 (EDM, NYR, LAK)",
    x = "Dimension Score (z-score)",
    y = "Goals For / 60",
    color = "Team"
  )

# 4. SAUVEGARDER ----

ggsave("outputs/figures/cluster5_dimensions_gf60.png", p,
       width = 14, height = 6, dpi = 150)

print(p)
cat("\nSauvegardé: outputs/figures/cluster5_dimensions_gf60.png\n")
