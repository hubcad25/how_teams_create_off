# Analyse et visualisation des clusters

library(tidyverse)
library(clessnize)

cat("ANALYSE DES CLUSTERS\n\n")

# 1. CHARGEMENT ----

df <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE) %>%
  mutate(cluster = factor(cluster))
profiles <- read_csv("outputs/tables/cluster_profiles.csv", show_col_types = FALSE)
metric_labels <- readRDS("data/processed/metric_labels.rds")

score_cols <- setdiff(names(df), c("team", "name", "cluster"))
n_clusters <- n_distinct(df$cluster)

# Cluster names
cluster_names_map <- c(
  "1" = "Crash & Hope",
  "2" = "High-Octane Drive",
  "3" = "Streaky Offense",
  "4" = "Selective Shooting",
  "5" = "Lane Creation",
  "6" = "Puck Hog & Finish"
)

cat("Données:", nrow(df), "équipes,", n_clusters, "clusters\n")
cat("Dimensions:", paste(score_cols, collapse = ", "), "\n\n")

# 1b. LOADINGS PAR DIMENSION ----

loadings <- read_csv("outputs/tables/dimension_loadings.csv", show_col_types = FALSE)

# Labels lisibles
loadings <- loadings %>%
  mutate(label = ifelse(variable %in% names(metric_labels),
                        metric_labels[variable],
                        gsub("^(input|output)_", "", variable)),
         # Rename dimensions to English
         dimension = case_when(
           dimension == "Misc_1" ~ "Recovery+Possession",
           dimension == "Misc_2" ~ "Puck exchanges",
           dimension == "Qualite" ~ "Quality",
           dimension == "Rebonds" ~ "Rebounds",
           dimension == "RecoveryPossession" ~ "Recovery+Possession",
           dimension == "PuckExchanges" ~ "Puck exchanges",
           TRUE ~ dimension
         ),
         dimension = factor(dimension,
                            levels = c("Volume", "Quality", "Penetration",
                                       "Rebounds", "Finishing", "Recovery+Possession",
                                       "Puck exchanges")))

p_loadings <- ggplot(loadings, aes(x = reorder(label, loading), y = loading,
                                    fill = loading > 0)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~dimension, scales = "free_y", ncol = 2) +
  scale_fill_manual(values = c("TRUE" = "#c0392b", "FALSE" = "#2980b9")) +
  coord_flip() +
  labs(
    title = "Loadings par dimension (FA à 1 facteur)",
    subtitle = "Contribution de chaque variable au score de la dimension",
    x = NULL,
    y = "Loading"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    strip.text = element_text(face = "bold", size = 12),
    axis.text.y = element_text(size = 9)
  )

ggsave("outputs/figures/03_dimension_loadings.png", p_loadings,
       width = 13, height = 12, dpi = 150)
cat("  outputs/figures/dimension_loadings.png\n\n")

# 2. HEATMAP DES PROFILS ----

profiles_long <- profiles %>%
  pivot_longer(cols = all_of(score_cols), names_to = "Dimension", values_to = "Score") %>%
  mutate(
    Dimension = case_when(
      Dimension == "Qualite" ~ "Quality",
      Dimension == "Rebonds" ~ "Rebounds",
      Dimension == "RecoveryPossession" ~ "Recovery+Possession",
      Dimension == "PuckExchanges" ~ "Puck exchanges",
      TRUE ~ Dimension
    ),
    Dimension = factor(Dimension, levels = c("Volume", "Quality", "Penetration",
                                             "Rebounds", "Finishing",
                                             "Recovery+Possession", "Puck exchanges"))
  )

p_heatmap <- ggplot(profiles_long, aes(x = Dimension, y = factor(cluster), fill = Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", Score)), size = 4.5, fontface = "bold") +
  scale_fill_gradient2(
    low = "#2980b9", mid = "white", high = "#c0392b",
    midpoint = 0, limits = c(-3, 3)
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

ggsave("outputs/figures/06_cluster_heatmap.png", p_heatmap, width = 10, height = 6, dpi = 150)

# 3. BARPLOT PAR CLUSTER ----

p_bars <- ggplot(profiles_long, aes(x = Dimension, y = Score, fill = Score > 0)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~cluster, ncol = 3,
             labeller = labeller(cluster = cluster_names_map)) +
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
    axis.text.x = element_text(angle = 90, hjust = 0.5, vjust = 0.5, size = 9),
    panel.border = element_rect(color = "grey85", fill = NA, linewidth = 0.5)
  )

ggsave("outputs/figures/06_cluster_profiles.png", p_bars, width = 12, height = 8, dpi = 150)

# 4. SCATTER: 2 DIMENSIONS PRINCIPALES ----

dim1 <- score_cols[1]
dim2 <- score_cols[2]

cluster_colors <- c("#e74c3c", "#3498db", "#27ae60", "#9b59b6",
                    "#f39c12", "#1abc9c", "#e91e63", "#795548")

p_scatter <- ggplot(df, aes(x = .data[[dim1]], y = .data[[dim2]], color = cluster, label = team)) +
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

ggsave("outputs/figures/06_scatter_main.png", p_scatter, width = 11, height = 8, dpi = 150)

# 5. SCATTER: GOALS/60 vs xG/60 PAR CLUSTER ----

df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

df_output <- df %>%
  left_join(df_metrics %>% select(team, output_goals_per60, input_xGoals_per60), by = "team")

p_goals_xg <- ggplot(df_output, aes(x = input_xGoals_per60, y = output_goals_per60,
                                     color = cluster, label = team)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", alpha = 0.4) +
  geom_point(size = 4, alpha = 0.85) +
  ggrepel::geom_text_repel(size = 3.2, max.overlaps = 32, show.legend = FALSE,
                            seed = 42, min.segment.length = 0.3) +
  scale_color_manual(values = cluster_colors[1:n_clusters]) +
  labs(
    title = "5v5 Offense: Actual vs Expected Goals",
    subtitle = "2025-26 Season | Above diagonal = outperforming expectations",
    x = "xG/60",
    y = "Goals/60",
    color = "Cluster"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40")
  )

ggsave("outputs/figures/06_goals_vs_xg.png", p_goals_xg, width = 11, height = 8, dpi = 150)
cat("  outputs/figures/cluster_goals_vs_xg.png\n")

# 5b. STRIP PLOT: GOALS/60 PAR CLUSTER ----

league_avg <- mean(df_output$output_goals_per60)

cluster_means <- df_output %>%
  group_by(cluster) %>%
  summarise(mean_goals = mean(output_goals_per60),
            sd_goals = sd(output_goals_per60),
            n = n(),
            .groups = "drop") %>%
  mutate(ci_lo = mean_goals - 1.96 * sd_goals,
         ci_hi = mean_goals + 1.96 * sd_goals,
         cluster_rank = rank(-mean_goals)) %>%
  arrange(cluster_rank)

# Réordonner les clusters par moyenne décroissante
cluster_order <- cluster_means$cluster
df_output <- df_output %>%
  mutate(cluster_ordered = factor(cluster, levels = rev(cluster_order)))

cluster_means <- cluster_means %>%
  mutate(cluster_ordered = factor(cluster, levels = rev(cluster_order)))

# Position y unique par équipe (dodge manuel)
df_strip <- df_output %>%
  arrange(cluster_ordered, output_goals_per60) %>%
  group_by(cluster_ordered) %>%
  mutate(y_dodge = as.numeric(cluster_ordered) +
           seq(-0.38, 0.38, length.out = n())) %>%
  ungroup()

cluster_means <- cluster_means %>%
  mutate(y_pos = as.numeric(cluster_ordered))

p_strip <- ggplot(df_strip, aes(x = output_goals_per60, y = y_dodge, color = cluster)) +
  geom_vline(xintercept = league_avg, linetype = "dotted", color = "grey50", linewidth = 0.5) +
  geom_rect(data = cluster_means,
            aes(xmin = ci_lo, xmax = ci_hi,
                ymin = y_pos - 0.45, ymax = y_pos + 0.45,
                fill = cluster),
            alpha = 0.06, color = NA, inherit.aes = FALSE, show.legend = FALSE) +
  geom_point(data = cluster_means,
             aes(x = mean_goals, y = y_pos, color = cluster),
             size = 22, alpha = 0.12, show.legend = FALSE) +
  geom_point(size = 3, alpha = 0.85, show.legend = FALSE) +
  geom_text(aes(label = team), size = 2.8, nudge_y = 0.2, show.legend = FALSE) +
  scale_color_manual(values = cluster_colors[1:n_clusters]) +
  scale_fill_manual(values = cluster_colors[1:n_clusters]) +
  scale_y_continuous(
    breaks = seq_along(cluster_order),
    labels = cluster_names_map[rev(as.character(cluster_order))]
  ) +
  labs(
    title = "Goals/60 by Cluster",
    subtitle = "Dotted line = league avg | Circle = cluster mean | Band = 95% CI",
    x = "Goals/60",
    y = NULL
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.text.y = element_text(size = 11, face = "bold"),
    panel.grid.major.y = element_blank()
  )

ggsave("outputs/figures/06_goals_strip.png", p_strip, width = 11, height = 7, dpi = 150)
cat("  outputs/figures/cluster_strip_goals.png\n")

# 6. RÉGRESSION SUR DONNÉES SIMULÉES (BOOTSTRAP PARAMÉTRIQUE) ----

cat("RÉGRESSION SUR DONNÉES SIMULÉES\n\n")

library(MASS)

set.seed(42)
N_SIM <- 500  # observations simulées par cluster
sim_vars <- c(score_cols, "output_goals_per60")

# Covariance régularisée (shrinkage vers diagonale)
shrink_cov <- function(x, lambda = 0.3) {
  S <- cov(x)
  D <- diag(diag(S))
  (1 - lambda) * S + lambda * D
}

# Générer observations synthétiques par cluster
df_sim <- map_dfr(levels(df_output$cluster), function(cl) {
  sub <- df_output %>% filter(cluster == cl) %>% dplyr::select(all_of(sim_vars))
  n_obs <- nrow(sub)
  mu <- colMeans(sub)

  # Plus de shrinkage pour petits clusters
  lam <- case_when(n_obs <= 3 ~ 0.7, n_obs <= 5 ~ 0.5, TRUE ~ 0.3)
  Sigma <- shrink_cov(sub, lambda = lam)

  synth <- mvrnorm(n = N_SIM, mu = mu, Sigma = Sigma)
  as_tibble(synth) %>% mutate(cluster = cl)
})

df_sim <- df_sim %>% mutate(cluster = factor(cluster))

cat(sprintf("  %d observations simulées (%d par cluster)\n\n",
            nrow(df_sim), N_SIM))

# Régression avec interactions cluster × dimensions
formula_interact <- as.formula(
  paste("output_goals_per60 ~ cluster * (",
        paste(score_cols, collapse = " + "), ")")
)

mod_sim <- lm(formula_interact, data = df_sim)
cat(sprintf("  R² = %.3f, R² adj = %.3f\n\n",
            summary(mod_sim)$r.squared, summary(mod_sim)$adj.r.squared))

# Modèle SANS interaction pour les coefficients de base
formula_main <- as.formula(
  paste("output_goals_per60 ~ cluster +",
        paste(score_cols, collapse = " + "))
)

mod_main <- lm(formula_main, data = df_sim)
main_coefs <- coef(mod_main)

# Extraire les effets par cluster (effet principal + interaction)
base_coefs <- coef(mod_sim)
ref_cluster <- levels(df_sim$cluster)[1]

sim_effects <- map_dfr(levels(df_sim$cluster), function(cl) {
  map_dfr(score_cols, function(dim) {
    # Effet de base (cluster de référence)
    base <- base_coefs[dim]
    # Interaction pour ce cluster
    interact_name <- paste0("cluster", cl, ":", dim)
    interact <- ifelse(cl == ref_cluster, 0,
                       ifelse(interact_name %in% names(base_coefs),
                              base_coefs[interact_name], 0))
    tibble(cluster = cl, dimension = dim, effect = base + interact)
  })
}) %>%
  mutate(cluster = factor(cluster, levels = c("2", "6", "4", "3", "1", "5")),
         dimension = factor(dimension, levels = score_cols))

# Ajouter les coefficients de base (modèle sans interaction)
base_effects <- tibble(
  cluster = "Base (no interaction)",
  dimension = score_cols,
  effect = main_coefs[score_cols]
) %>%
  mutate(cluster = factor(cluster, levels = c("Base (no interaction)", levels(sim_effects$cluster))),
         dimension = factor(dimension, levels = score_cols))

sim_effects <- bind_rows(base_effects, sim_effects)

# Créer des labels personnalisés pour l'axe des Y
sim_effects <- sim_effects %>%
  mutate(
    cluster_label = ifelse(cluster == "Base (no interaction)",
                          "Base (no interaction)",
                          cluster_names_map[as.character(cluster)])
  )

# Ordre des clusters pour l'axe Y
cluster_order_sim <- c("Base (no interaction)",
                       "2", "6", "4", "3", "1", "5")  # Ordre par performance décroissante
cluster_labels_sim <- c("Base (no interaction)",
                       "High-Octane Drive", "Puck Hog & Finish", "Selective Shooting",
                       "Streaky Offense", "Crash & Hope", "Lane Creation")

# Heatmap des effets
p_sim_effects <- ggplot(sim_effects,
                        aes(x = dimension, y = cluster, fill = effect)) +
  geom_tile(color = "white", linewidth = 0.5) +
  # Ajouter un bordure distinctive pour la rangée "Base"
  geom_tile(data = sim_effects %>% filter(cluster == "Base (no interaction)"),
            aes(x = dimension, y = cluster),
            fill = NA, color = "#2c3e50", linewidth = 2.5, inherit.aes = FALSE) +
  geom_text(aes(label = sprintf("%.2f", effect)), size = 4, fontface = "bold") +
  scale_fill_gradient2(
    low = "#2980b9", mid = "white", high = "#c0392b",
    midpoint = 0
  ) +
  scale_y_discrete(labels = cluster_labels_sim) +
  labs(
    title = "Dimension Effects on Goals/60 by Cluster",
    subtitle = sprintf("Top row: main effects (no interaction) | Other rows: cluster-specific effects (interaction) | %d simulated obs",
                       nrow(df_sim)),
    x = NULL,
    y = "Cluster",
    fill = "Coefficient"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.text.x = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 12)
  )

ggsave("outputs/figures/06_regression_effects.png", p_sim_effects,
       width = 11, height = 6, dpi = 150)
cat("  outputs/figures/cluster_sim_effects.png\n")

write_csv(sim_effects, "outputs/tables/sim_regression_effects.csv")
cat("  outputs/tables/sim_regression_effects.csv\n\n")

# 7. RÉSUMÉ ----

cat("RÉSUMÉ DES CLUSTERS\n\n")

for (cl in sort(unique(df$cluster))) {
  teams <- df %>% filter(cluster == cl) %>% pull(team)
  profile <- profiles %>% filter(cluster == cl)

  cat(sprintf("CLUSTER %s (%d équipes): %s\n", cl, length(teams), paste(teams, collapse = ", ")))

  scores <- profile %>% dplyr::select(all_of(score_cols)) %>% unlist()
  top_pos <- names(sort(scores, decreasing = TRUE))[1:2]
  top_neg <- names(sort(scores, decreasing = FALSE))[1:2]

  cat(sprintf("  Haut: %s (%.2f), %s (%.2f)\n",
              top_pos[1], scores[top_pos[1]], top_pos[2], scores[top_pos[2]]))
  cat(sprintf("  Bas:  %s (%.2f), %s (%.2f)\n",
              top_neg[1], scores[top_neg[1]], top_neg[2], scores[top_neg[2]]))
  cat("\n")
}

# 7. EXPORT FINAL ----

export_table <- df %>%
  dplyr::select(team, cluster, all_of(score_cols)) %>%
  arrange(cluster, team) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

write_csv(export_table, "outputs/tables/teams_with_scores.csv")

cat("Fichiers sauvegardés:\n")
cat("  outputs/figures/cluster_heatmap.png\n")
cat("  outputs/figures/cluster_bars.png\n")
cat("  outputs/figures/cluster_scatter_main.png\n")
cat("  outputs/tables/teams_with_scores.csv\n")
