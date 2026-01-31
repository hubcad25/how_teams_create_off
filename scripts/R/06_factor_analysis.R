# =============================================================================
# Factor Analysis - Interprétation des clusters
# =============================================================================

library(tidyverse)
library(psych)
library(clessnize)

cat("=============================================================================\n")
cat("FACTOR ANALYSIS\n")
cat("=============================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. CHARGEMENT
# -----------------------------------------------------------------------------

df <- read_csv("data/processed/team_metrics_clustered.csv", show_col_types = FALSE)
metric_labels <- readRDS("data/processed/metric_labels.rds")

# Variables INPUT seulement
input_vars <- df %>% select(starts_with("input_")) %>% names()
df_inputs <- df %>% select(all_of(input_vars))

cat("Données:", nrow(df), "équipes,", length(input_vars), "variables\n\n")

# -----------------------------------------------------------------------------
# 2. DÉTERMINER LE NOMBRE DE FACTEURS
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("NOMBRE DE FACTEURS\n")
cat("=============================================================================\n\n")

# Kaiser (eigenvalues > 1)
eigen_vals <- eigen(cor(df_inputs))$values
n_factors_kaiser <- sum(eigen_vals > 1)

cat("Kaiser (eigenvalue > 1):", n_factors_kaiser, "facteurs\n")

# On utilise 5 facteurs (similaire aux 5 dimensions théoriques du CLAUDE.md)
n_factors <- 5

cat("→ On utilise", n_factors, "facteurs\n\n")

# -----------------------------------------------------------------------------
# 3. FACTOR ANALYSIS
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("FACTOR ANALYSIS (", n_factors, " facteurs, rotation varimax)\n")
cat("=============================================================================\n\n")

fa_result <- fa(df_inputs, nfactors = n_factors, rotate = "varimax", fm = "minres", scores = "regression")

# Variance expliquée
var_explained <- fa_result$Vaccounted
cat("Variance expliquée par facteur:\n")
print(round(var_explained[1:3, ], 3))
cat("\n")

# -----------------------------------------------------------------------------
# 4. LOADINGS PAR FACTEUR
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("LOADINGS DOMINANTS PAR FACTEUR\n")
cat("=============================================================================\n\n")

loadings_df <- as_tibble(fa_result$loadings[], rownames = "variable") %>%
  mutate(label = sapply(variable, function(v) {
    l <- metric_labels[v]
    if (is.na(l)) gsub("input_", "", v) else l
  }))

# Renommer les colonnes des facteurs
factor_cols <- colnames(loadings_df)[grepl("^MR|^ML|^PA", colnames(loadings_df))]
new_names <- paste0("F", 1:length(factor_cols))
loadings_df <- loadings_df %>%
  rename_with(~new_names, all_of(factor_cols))

# Fonction pour afficher les top loadings d'un facteur
print_factor <- function(factor_num, loadings_df, top_n = 8) {
  col_name <- paste0("F", factor_num)

  top_loadings <- loadings_df %>%
    select(variable, label, loading = all_of(col_name)) %>%
    arrange(desc(abs(loading))) %>%
    head(top_n)

  cat(sprintf("FACTEUR %d:\n", factor_num))
  for (i in 1:nrow(top_loadings)) {
    sign <- ifelse(top_loadings$loading[i] > 0, "+", "-")
    cat(sprintf("  %s%.3f  %s\n", sign, abs(top_loadings$loading[i]), top_loadings$label[i]))
  }
  cat("\n")
}

for (f in 1:n_factors) {
  print_factor(f, loadings_df)
}

# -----------------------------------------------------------------------------
# 5. SCORES DES ÉQUIPES
# -----------------------------------------------------------------------------

# Extraire les scores
scores <- as_tibble(fa_result$scores)
colnames(scores) <- paste0("F", 1:n_factors)

df_scores <- df %>%
  select(team, cluster) %>%
  bind_cols(scores)

# -----------------------------------------------------------------------------
# 6. PROFIL DES CLUSTERS PAR FACTEUR
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("PROFIL DES CLUSTERS PAR FACTEUR\n")
cat("=============================================================================\n\n")

cluster_profiles <- df_scores %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    across(starts_with("F"), mean),
    .groups = "drop"
  )

print(cluster_profiles %>% mutate(across(where(is.numeric) & !n, ~round(., 2))))

cat("\n")

# -----------------------------------------------------------------------------
# 7. VISUALISATION: HEATMAP DES PROFILS
# -----------------------------------------------------------------------------

profiles_long <- cluster_profiles %>%
  pivot_longer(cols = starts_with("F"), names_to = "Factor", values_to = "Score")

p_heatmap <- ggplot(profiles_long, aes(x = Factor, y = cluster, fill = Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", Score)), size = 4) +
  scale_fill_gradient2(
    low = "#2980b9", mid = "white", high = "#c0392b",
    midpoint = 0, limits = c(-1.5, 1.5)
  ) +
  labs(
    title = "Profil des clusters par facteur",
    subtitle = sprintf("%d facteurs (FA varimax)", n_factors),
    x = "Facteur",
    y = "Cluster",
    fill = "Score"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text = element_text(size = 11)
  )

ggsave("outputs/figures/cluster_factor_profiles.png", p_heatmap, width = 10, height = 6, dpi = 150)

# -----------------------------------------------------------------------------
# 8. VISUALISATION: BARPLOT PAR CLUSTER
# -----------------------------------------------------------------------------

p_bars <- ggplot(profiles_long, aes(x = Factor, y = Score, fill = Score > 0)) +
  geom_col(show.legend = FALSE) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~cluster, ncol = 3, labeller = labeller(cluster = function(x) paste("Cluster", x))) +
  scale_fill_manual(values = c("TRUE" = "#27ae60", "FALSE" = "#e74c3c")) +
  labs(
    title = "Score moyen par facteur et cluster",
    x = "Facteur",
    y = "Score moyen (z)"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

ggsave("outputs/figures/cluster_factor_bars.png", p_bars, width = 12, height = 8, dpi = 150)

# -----------------------------------------------------------------------------
# 9. SAUVEGARDE
# -----------------------------------------------------------------------------

# Scores des équipes
write_csv(df_scores, "outputs/tables/team_factor_scores.csv")

# Profils des clusters
write_csv(cluster_profiles, "outputs/tables/cluster_factor_profiles.csv")

# Loadings
write_csv(loadings_df, "outputs/tables/factor_loadings.csv")

# Objet FA
saveRDS(fa_result, "data/processed/fa_result.rds")

cat("=============================================================================\n")
cat("FICHIERS SAUVEGARDÉS\n")
cat("=============================================================================\n\n")
cat("✓ outputs/tables/team_factor_scores.csv\n")
cat("✓ outputs/tables/cluster_factor_profiles.csv\n")
cat("✓ outputs/tables/factor_loadings.csv\n")
cat("✓ outputs/figures/cluster_factor_profiles.png\n")
cat("✓ outputs/figures/cluster_factor_bars.png\n")
cat("✓ data/processed/fa_result.rds\n")
