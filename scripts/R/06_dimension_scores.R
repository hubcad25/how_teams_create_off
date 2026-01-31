# =============================================================================
# Scores par dimension théorique (FA pondérée)
# =============================================================================

library(tidyverse)
library(psych)
library(clessnize)

cat("=============================================================================\n")
cat("SCORES PAR DIMENSION THÉORIQUE\n")
cat("=============================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. CHARGEMENT
# -----------------------------------------------------------------------------

df <- read_csv("data/processed/team_metrics_clustered.csv", show_col_types = FALSE)
metric_labels <- readRDS("data/processed/metric_labels.rds")

# -----------------------------------------------------------------------------
# 2. DÉFINITION DES DIMENSIONS THÉORIQUES
# -----------------------------------------------------------------------------

dimensions <- list(

  Volume = c(
    "input_shotAttempts_per60",
    "input_unblockedShots_per60",
    "input_shotsOnGoal_per60",
    "input_xGoals_per60",
    "input_corsi_pct",
    "input_fenwick_pct"
  ),

  Qualite = c(
    "input_xG_per_shotAttempt",
    "input_xG_per_unblockedShot",
    "input_xG_per_SOG",
    "input_pct_highDanger",
    "input_pct_mediumDanger",
    "input_ratio_HD_LD",
    "input_ratio_HD_MD",
    "input_ratio_MD_LD"
  ),

  Penetration = c(
    "input_shot_completion_rate",
    "input_blocked_shot_rate",
    "input_missed_net_rate"
  ),

  Rebonds = c(
    "input_rebounds_per60",
    "input_xG_per_rebound",
    "input_pct_xG_from_rebounds"
  ),

  Misc = c(
    "input_takeaways_per60",
    "input_giveaways_per60",
    "input_takeaway_giveaway_ratio",
    "input_penalty_differential_per60",
    "input_penalties_taken_per60",
    "input_faceoff_win_pct",
    "input_hits_per60",
    "input_zone_exit_success"
  )
)

cat("Dimensions définies:\n")
for (dim_name in names(dimensions)) {
  cat(sprintf("  %s: %d variables\n", dim_name, length(dimensions[[dim_name]])))
}
cat("\n")

# -----------------------------------------------------------------------------
# 3. FA PAR DIMENSION + SCORE PONDÉRÉ
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("FACTOR ANALYSIS PAR DIMENSION\n")
cat("=============================================================================\n\n")

# Fonction pour calculer le score pondéré d'une dimension
compute_dimension_score <- function(df, vars, dim_name) {

  # Extraire et standardiser les variables
  data <- df %>% select(all_of(vars))
  data_scaled <- scale(data)

  # FA à 1 facteur
  fa_result <- fa(data_scaled, nfactors = 1, rotate = "none", fm = "minres", scores = "regression")

  # Loadings
  loadings <- fa_result$loadings[, 1]

  # Variance expliquée
  var_explained <- fa_result$Vaccounted["Proportion Var", 1]

  # Afficher résultats
  cat(sprintf("%s (%.0f%% variance):\n", dim_name, var_explained * 100))

  loadings_sorted <- sort(loadings, decreasing = TRUE)
  for (i in seq_along(loadings_sorted)) {
    var_name <- names(loadings_sorted)[i]
    label <- metric_labels[var_name]
    if (is.na(label)) label <- gsub("input_", "", var_name)
    sign <- ifelse(loadings_sorted[i] > 0, "+", "-")
    cat(sprintf("  %s%.3f  %s\n", sign, abs(loadings_sorted[i]), label))
  }
  cat("\n")

  # Score = moyenne pondérée par loadings (en valeur absolue pour la direction)
  # On utilise les scores de la FA directement
  scores <- fa_result$scores[, 1]

  return(list(
    scores = scores,
    loadings = loadings,
    var_explained = var_explained,
    fa_result = fa_result
  ))
}

# Calculer pour chaque dimension
dimension_results <- list()
score_matrix <- matrix(NA, nrow = nrow(df), ncol = length(dimensions))
colnames(score_matrix) <- names(dimensions)

for (i in seq_along(dimensions)) {
  dim_name <- names(dimensions)[i]
  vars <- dimensions[[dim_name]]

  result <- compute_dimension_score(df, vars, dim_name)
  dimension_results[[dim_name]] <- result
  score_matrix[, i] <- result$scores
}

# -----------------------------------------------------------------------------
# 4. AJOUTER SCORES AU DATAFRAME
# -----------------------------------------------------------------------------

df_scores <- df %>%
  select(team, cluster) %>%
  bind_cols(as_tibble(score_matrix))

# -----------------------------------------------------------------------------
# 5. PROFIL DES CLUSTERS
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("PROFIL DES CLUSTERS PAR DIMENSION\n")
cat("=============================================================================\n\n")

cluster_profiles <- df_scores %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    across(all_of(names(dimensions)), mean),
    .groups = "drop"
  )

print(cluster_profiles %>% mutate(across(where(is.numeric) & !c(n), ~round(., 2))))

cat("\n")

# Équipes par cluster avec scores
cat("=============================================================================\n")
cat("ÉQUIPES PAR CLUSTER\n")
cat("=============================================================================\n\n")

for (cl in sort(unique(df_scores$cluster))) {
  teams <- df_scores %>% filter(cluster == cl) %>% pull(team)
  cat(sprintf("Cluster %d: %s\n", cl, paste(teams, collapse = ", ")))
}

cat("\n")

# -----------------------------------------------------------------------------
# 6. VISUALISATION: HEATMAP
# -----------------------------------------------------------------------------

profiles_long <- cluster_profiles %>%
  pivot_longer(cols = all_of(names(dimensions)), names_to = "Dimension", values_to = "Score") %>%
  mutate(Dimension = factor(Dimension, levels = names(dimensions)))

p_heatmap <- ggplot(profiles_long, aes(x = Dimension, y = factor(cluster), fill = Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", Score)), size = 4.5, fontface = "bold") +
  scale_fill_gradient2(
    low = "#2980b9", mid = "white", high = "#c0392b",
    midpoint = 0, limits = c(-2, 2)
  ) +
  labs(
    title = "Profil des clusters par dimension théorique",
    subtitle = "Score = FA pondérée (z-score)",
    x = NULL,
    y = "Cluster",
    fill = "Score"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 0, size = 11, face = "bold"),
    axis.text.y = element_text(size = 12)
  )

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("outputs/figures/cluster_dimension_heatmap.png", p_heatmap, width = 10, height = 6, dpi = 150)

# -----------------------------------------------------------------------------
# 7. VISUALISATION: BARPLOT PAR CLUSTER
# -----------------------------------------------------------------------------

p_bars <- ggplot(profiles_long, aes(x = Dimension, y = Score, fill = Score > 0)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~cluster, ncol = 3, labeller = labeller(cluster = function(x) paste("Cluster", x))) +
  scale_fill_manual(values = c("TRUE" = "#27ae60", "FALSE" = "#e74c3c")) +
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

ggsave("outputs/figures/cluster_dimension_bars.png", p_bars, width = 12, height = 8, dpi = 150)

# -----------------------------------------------------------------------------
# 8. VARIANCE EXPLIQUÉE PAR DIMENSION
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("VARIANCE EXPLIQUÉE PAR DIMENSION\n")
cat("=============================================================================\n\n")

var_summary <- tibble(
  Dimension = names(dimensions),
  n_vars = sapply(dimensions, length),
  Variance_pct = sapply(dimension_results, function(x) x$var_explained) * 100
)

print(var_summary %>% mutate(Variance_pct = round(Variance_pct, 1)))

cat("\n")

# -----------------------------------------------------------------------------
# 9. SAUVEGARDE
# -----------------------------------------------------------------------------

# Scores des équipes
write_csv(df_scores, "outputs/tables/team_dimension_scores.csv")

# Profils des clusters
write_csv(cluster_profiles, "outputs/tables/cluster_dimension_profiles.csv")

# Loadings par dimension
loadings_all <- map_dfr(names(dimension_results), function(dim_name) {
  loadings <- dimension_results[[dim_name]]$loadings
  tibble(
    dimension = dim_name,
    variable = names(loadings),
    loading = as.numeric(loadings)
  )
})
write_csv(loadings_all, "outputs/tables/dimension_loadings.csv")

# Résultats FA
saveRDS(dimension_results, "data/processed/dimension_fa_results.rds")

cat("=============================================================================\n")
cat("FICHIERS SAUVEGARDÉS\n")
cat("=============================================================================\n\n")
cat("✓ outputs/tables/team_dimension_scores.csv\n")
cat("✓ outputs/tables/cluster_dimension_profiles.csv\n")
cat("✓ outputs/tables/dimension_loadings.csv\n")
cat("✓ outputs/figures/cluster_dimension_heatmap.png\n")
cat("✓ outputs/figures/cluster_dimension_bars.png\n")
cat("✓ data/processed/dimension_fa_results.rds\n")
