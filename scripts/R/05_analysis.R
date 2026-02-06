# Analyse et visualisation des clusters

library(tidyverse)
library(clessnize)

cat("ANALYSE DES CLUSTERS\n\n")

# 1. CHARGEMENT ----

df <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE)
profiles <- read_csv("outputs/tables/cluster_profiles.csv", show_col_types = FALSE)
metric_labels <- readRDS("data/processed/metric_labels.rds")

score_cols <- setdiff(names(df), c("team", "name", "cluster"))
n_clusters <- n_distinct(df$cluster)

cat("Données:", nrow(df), "équipes,", n_clusters, "clusters\n")
cat("Dimensions:", paste(score_cols, collapse = ", "), "\n\n")

# 2. HEATMAP DES PROFILS ----

profiles_long <- profiles %>%
  pivot_longer(cols = all_of(score_cols), names_to = "Dimension", values_to = "Score") %>%
  mutate(Dimension = factor(Dimension, levels = score_cols))

p_heatmap <- ggplot(profiles_long, aes(x = Dimension, y = factor(cluster), fill = Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", Score)), size = 4.5, fontface = "bold") +
  scale_fill_gradient2(
    low = "#2980b9", mid = "white", high = "#c0392b",
    midpoint = 0, limits = c(-2.5, 2.5)
  ) +
  labs(
    title = "Profil des clusters par dimension",
    x = NULL,
    y = "Cluster",
    fill = "Score (z)"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 12)
  )

ggsave("outputs/figures/cluster_heatmap.png", p_heatmap, width = 10, height = 6, dpi = 150)

# 3. BARPLOT PAR CLUSTER ----

p_bars <- ggplot(profiles_long, aes(x = Dimension, y = Score, fill = Score > 0)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~cluster, ncol = 3,
             labeller = labeller(cluster = function(x) paste("Cluster", x))) +
  scale_fill_manual(values = c("TRUE" = "#27ae60", "FALSE" = "#e74c3c")) +
  coord_cartesian(ylim = c(-3, 3)) +
  labs(
    title = "Score moyen par dimension et cluster",
    x = NULL,
    y = "Score (z)"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9)
  )

ggsave("outputs/figures/cluster_bars.png", p_bars, width = 12, height = 8, dpi = 150)

# 4. SCATTER: 2 DIMENSIONS PRINCIPALES ----

dim1 <- score_cols[1]
dim2 <- score_cols[2]

cluster_colors <- c("#e74c3c", "#3498db", "#27ae60", "#9b59b6",
                    "#f39c12", "#1abc9c", "#e91e63", "#795548")

p_scatter <- ggplot(df, aes_string(x = dim1, y = dim2, color = "cluster", label = "team")) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_point(size = 4, alpha = 0.8) +
  geom_text(nudge_y = 0.2, size = 3, show.legend = FALSE) +
  scale_color_manual(values = cluster_colors[1:n_clusters]) +
  labs(
    title = sprintf("Clusters: %s vs %s", dim1, dim2),
    x = dim1,
    y = dim2,
    color = "Cluster"
  ) +
  theme_clean_light() +
  theme(plot.title = element_text(face = "bold"))

ggsave("outputs/figures/cluster_scatter_main.png", p_scatter, width = 11, height = 8, dpi = 150)

# 5. RÉSUMÉ ----

cat("RÉSUMÉ DES CLUSTERS\n\n")

for (cl in sort(unique(df$cluster))) {
  teams <- df %>% filter(cluster == cl) %>% pull(team)
  profile <- profiles %>% filter(cluster == cl)

  cat(sprintf("CLUSTER %s (%d équipes): %s\n", cl, length(teams), paste(teams, collapse = ", ")))

  scores <- profile %>% select(all_of(score_cols)) %>% unlist()
  top_pos <- names(sort(scores, decreasing = TRUE))[1:2]
  top_neg <- names(sort(scores, decreasing = FALSE))[1:2]

  cat(sprintf("  Haut: %s (%.2f), %s (%.2f)\n",
              top_pos[1], scores[top_pos[1]], top_pos[2], scores[top_pos[2]]))
  cat(sprintf("  Bas:  %s (%.2f), %s (%.2f)\n",
              top_neg[1], scores[top_neg[1]], top_neg[2], scores[top_neg[2]]))
  cat("\n")
}

# 6. EXPORT FINAL ----

export_table <- df %>%
  select(team, cluster, all_of(score_cols)) %>%
  arrange(cluster, team) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

write_csv(export_table, "outputs/tables/teams_with_scores.csv")

cat("Fichiers sauvegardés:\n")
cat("  outputs/figures/cluster_heatmap.png\n")
cat("  outputs/figures/cluster_bars.png\n")
cat("  outputs/figures/cluster_scatter_main.png\n")
cat("  outputs/tables/teams_with_scores.csv\n")
