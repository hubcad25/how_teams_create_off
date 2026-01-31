# =============================================================================
# Analyse en Composantes Principales (PCA)
# Objectifs: 1. Variance expliquée  2. Interprétation PC  3. Réduction pour clustering
# =============================================================================

library(tidyverse)
library(clessnize)

# =============================================================================
# 1. CHARGEMENT DES DONNÉES
# =============================================================================

cat("=============================================================================\n")
cat("ANALYSE EN COMPOSANTES PRINCIPALES (PCA)\n")
cat("=============================================================================\n\n")

df <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

# Charger les labels pour les graphiques
metric_labels <- readRDS("data/processed/metric_labels.rds")

# Fonction helper pour récupérer un label
get_label <- function(var_name) {
  label <- metric_labels[var_name]
  if (is.na(label)) return(gsub("input_|output_", "", var_name))
  return(unname(label))
}

# Extraire seulement les variables INPUT
df_inputs <- df %>%
  select(starts_with("input_"))

cat("Données chargées:\n")
cat("  - Équipes:", nrow(df), "\n")
cat("  - Variables INPUT:", ncol(df_inputs), "\n\n")

# =============================================================================
# 2. VÉRIFICATION DE LA MULTICOLINÉARITÉ
# =============================================================================

cat("=============================================================================\n")
cat("MATRICE DE CORRÉLATION (variables très corrélées)\n")
cat("=============================================================================\n\n")

cor_matrix <- cor(df_inputs)

# Trouver les paires très corrélées (|r| > 0.85)
high_cor <- which(abs(cor_matrix) > 0.85 & upper.tri(cor_matrix), arr.ind = TRUE)

if (nrow(high_cor) > 0) {
  cat("Paires avec |r| > 0.85:\n")
  for (i in 1:nrow(high_cor)) {
    var1 <- colnames(cor_matrix)[high_cor[i, 1]]
    var2 <- colnames(cor_matrix)[high_cor[i, 2]]
    r <- cor_matrix[high_cor[i, 1], high_cor[i, 2]]
    label1 <- get_label(var1)
    label2 <- get_label(var2)
    cat(sprintf("  %.3f : %s <-> %s\n", r, label1, label2))
  }
  cat("\n")
}

# =============================================================================
# 3. PCA (avec standardisation)
# =============================================================================

cat("=============================================================================\n")
cat("PCA - RÉSULTATS\n")
cat("=============================================================================\n\n")

# Exécuter PCA avec centrage et scaling (z-scores)
pca_result <- prcomp(df_inputs, center = TRUE, scale. = TRUE)

# Extraire les éléments clés
eigenvalues <- pca_result$sdev^2
variance_pct <- eigenvalues / sum(eigenvalues) * 100
variance_cumul <- cumsum(variance_pct)
loadings <- pca_result$rotation
scores <- pca_result$x

# =============================================================================
# 4. VARIANCE EXPLIQUÉE
# =============================================================================

cat("VARIANCE EXPLIQUÉE PAR COMPOSANTE:\n")
cat("---------------------------------\n\n")

variance_df <- tibble(
  PC = paste0("PC", 1:length(eigenvalues)),
  Eigenvalue = eigenvalues,
  Variance_pct = variance_pct,
  Cumulative_pct = variance_cumul
)

# Afficher les 15 premières PC
print(variance_df %>%
        head(15) %>%
        mutate(across(where(is.numeric), ~round(., 2))))

cat("\n")

# Règles de sélection
cat("CRITÈRES DE SÉLECTION DU NOMBRE DE PC:\n")
cat("--------------------------------------\n")

# Kaiser: eigenvalue > 1
n_kaiser <- sum(eigenvalues > 1)
cat(sprintf("  Kaiser (eigenvalue > 1): %d composantes\n", n_kaiser))

# 70% variance
n_70pct <- which(variance_cumul >= 70)[1]
cat(sprintf("  70%% variance cumulée: %d composantes (%.1f%%)\n", n_70pct, variance_cumul[n_70pct]))

# 80% variance
n_80pct <- which(variance_cumul >= 80)[1]
cat(sprintf("  80%% variance cumulée: %d composantes (%.1f%%)\n", n_80pct, variance_cumul[n_80pct]))

# 90% variance
n_90pct <- which(variance_cumul >= 90)[1]
cat(sprintf("  90%% variance cumulée: %d composantes (%.1f%%)\n", n_90pct, variance_cumul[n_90pct]))

cat("\n")

# =============================================================================
# 5. SCREE PLOT (manuel, pas factoextra)
# =============================================================================

cat("Génération des graphiques...\n\n")

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)

# Scree plot avec variance cumulée
p_scree <- ggplot(variance_df %>% head(15), aes(x = reorder(PC, -Eigenvalue))) +
  geom_col(aes(y = Variance_pct), fill = "#2c3e50", alpha = 0.8) +
  geom_line(aes(y = Cumulative_pct, group = 1), color = "#e74c3c", linewidth = 1) +
  geom_point(aes(y = Cumulative_pct), color = "#e74c3c", size = 3) +
  geom_hline(yintercept = 70, linetype = "dashed", color = "#27ae60", alpha = 0.7) +
  geom_hline(yintercept = 80, linetype = "dashed", color = "#f39c12", alpha = 0.7) +
  annotate("text", x = 14, y = 72, label = "70%", color = "#27ae60", size = 3) +
  annotate("text", x = 14, y = 82, label = "80%", color = "#f39c12", size = 3) +
  scale_x_discrete(labels = function(x) gsub("PC", "", x)) +
  labs(
    title = "Scree Plot - Variance expliquée par composante",
    subtitle = "Barres = variance individuelle | Ligne = variance cumulée",
    x = "Composante Principale",
    y = "Variance expliquée (%)"
  ) +
  clessnize::theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(size = 10)
  )

ggsave("outputs/figures/pca_scree_plot.png", p_scree, width = 10, height = 6, dpi = 150)

# =============================================================================
# 6. INTERPRÉTATION DES COMPOSANTES PRINCIPALES
# =============================================================================

cat("=============================================================================\n")
cat("INTERPRÉTATION DES COMPOSANTES PRINCIPALES\n")
cat("=============================================================================\n\n")

# Fonction pour afficher les loadings dominants d'une PC
interpret_pc <- function(pc_num, loadings, top_n = 8) {
  pc_loadings <- loadings[, pc_num]

  # Trier par valeur absolue
  sorted_idx <- order(abs(pc_loadings), decreasing = TRUE)
  top_vars <- names(pc_loadings)[sorted_idx[1:top_n]]
  top_vals <- pc_loadings[sorted_idx[1:top_n]]

  cat(sprintf("PC%d (%.1f%% variance):\n", pc_num, variance_pct[pc_num]))
  cat("  Loadings dominants:\n")

  for (i in 1:top_n) {
    label <- get_label(top_vars[i])
    direction <- ifelse(top_vals[i] > 0, "+", "-")
    cat(sprintf("    %s %.3f  %s\n", direction, abs(top_vals[i]), label))
  }
  cat("\n")
}

# Interpréter les 6 premières PC
for (i in 1:6) {
  interpret_pc(i, loadings)
}

# =============================================================================
# 7. HEATMAP DES LOADINGS (top 6 PC)
# =============================================================================

# Préparer données pour heatmap avec labels propres
loadings_df <- as_tibble(loadings[, 1:6], rownames = "variable") %>%
  mutate(label = sapply(variable, get_label)) %>%
  pivot_longer(c(-variable, -label), names_to = "PC", values_to = "loading")

# Ordonner variables par loading sur PC1
var_order <- loadings_df %>%
  filter(PC == "PC1") %>%
  arrange(loading) %>%
  pull(label)

loadings_df <- loadings_df %>%
  mutate(label = factor(label, levels = var_order))

p_heatmap <- ggplot(loadings_df, aes(x = PC, y = label, fill = loading)) +
  geom_tile(color = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.2f", loading)), size = 2.5) +
  scale_fill_gradient2(
    low = "#2980b9", mid = "white", high = "#c0392b",
    midpoint = 0, limits = c(-1, 1)
  ) +
  labs(
    title = "Loadings des variables sur les 6 premières PC",
    x = "Composante Principale",
    y = NULL,
    fill = "Loading"
  ) +
  clessnize::theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    axis.text.y = element_text(size = 8),
    axis.text.x = element_text(size = 10)
  )

ggsave("outputs/figures/pca_loadings_heatmap.png", p_heatmap, width = 10, height = 12, dpi = 150)

# =============================================================================
# 8. BIPLOT PC1 vs PC2 (manuel)
# =============================================================================

# Scores des équipes
scores_df <- as_tibble(scores[, 1:4]) %>%
  mutate(team = df$team)

p_biplot <- ggplot(scores_df, aes(x = PC1, y = PC2, label = team)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_point(size = 3, color = "#2c3e50", alpha = 0.7) +
  geom_text(nudge_y = 0.3, size = 3) +
  labs(
    title = "PCA - Position des équipes (PC1 vs PC2)",
    subtitle = sprintf("PC1: %.1f%% | PC2: %.1f%% (Total: %.1f%%)",
                       variance_pct[1], variance_pct[2], variance_cumul[2]),
    x = sprintf("PC1 (%.1f%%)", variance_pct[1]),
    y = sprintf("PC2 (%.1f%%)", variance_pct[2])
  ) +
  clessnize::theme_clean_light() +
  theme(plot.title = element_text(face = "bold"))

ggsave("outputs/figures/pca_biplot_pc1_pc2.png", p_biplot, width = 10, height = 8, dpi = 150)

# PC1 vs PC3
p_biplot_13 <- ggplot(scores_df, aes(x = PC1, y = PC3, label = team)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_point(size = 3, color = "#2c3e50", alpha = 0.7) +
  geom_text(nudge_y = 0.3, size = 3) +
  labs(
    title = "PCA - Position des équipes (PC1 vs PC3)",
    subtitle = sprintf("PC1: %.1f%% | PC3: %.1f%% (Total: %.1f%%)",
                       variance_pct[1], variance_pct[3], variance_pct[1] + variance_pct[3]),
    x = sprintf("PC1 (%.1f%%)", variance_pct[1]),
    y = sprintf("PC3 (%.1f%%)", variance_pct[3])
  ) +
  clessnize::theme_clean_light() +
  theme(plot.title = element_text(face = "bold"))

ggsave("outputs/figures/pca_biplot_pc1_pc3.png", p_biplot_13, width = 10, height = 8, dpi = 150)

# =============================================================================
# 9. SAUVEGARDE DES RÉSULTATS
# =============================================================================

cat("=============================================================================\n")
cat("SAUVEGARDE DES RÉSULTATS\n")
cat("=============================================================================\n\n")

# Sauvegarder variance expliquée
write_csv(variance_df, "outputs/tables/pca_variance_explained.csv")
cat("  ✓ outputs/tables/pca_variance_explained.csv\n")

# Sauvegarder loadings complets (avec labels)
loadings_full <- as_tibble(loadings, rownames = "variable") %>%
  mutate(label = sapply(variable, get_label), .after = variable)
write_csv(loadings_full, "outputs/tables/pca_loadings.csv")
cat("  ✓ outputs/tables/pca_loadings.csv\n")

# Sauvegarder scores des équipes
scores_full <- as_tibble(scores) %>%
  mutate(team = df$team, .before = 1)
write_csv(scores_full, "outputs/tables/pca_team_scores.csv")
cat("  ✓ outputs/tables/pca_team_scores.csv\n")

# Sauvegarder objet PCA pour clustering
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
saveRDS(pca_result, "data/processed/pca_result.rds")
cat("  ✓ data/processed/pca_result.rds\n")

cat("\n")

# =============================================================================
# 10. RECOMMANDATION FINALE
# =============================================================================

cat("=============================================================================\n")
cat("RECOMMANDATION POUR LE CLUSTERING\n")
cat("=============================================================================\n\n")

cat("Résumé:\n")
cat(sprintf("  - Kaiser (eigenvalue > 1): %d PC\n", n_kaiser))
cat(sprintf("  - 70%% variance: %d PC\n", n_70pct))
cat(sprintf("  - 80%% variance: %d PC\n", n_80pct))
cat("\n")

# Recommandation basée sur coude + interprétabilité
recommended_n <- n_70pct
cat(sprintf("RECOMMANDATION: Utiliser %d composantes principales\n", recommended_n))
cat(sprintf("  → Variance cumulée: %.1f%%\n", variance_cumul[recommended_n]))
cat(sprintf("  → Réduction: %d variables → %d dimensions\n", ncol(df_inputs), recommended_n))
cat("\n")

cat("Figures générées:\n")
cat("  ✓ outputs/figures/pca_scree_plot.png\n")
cat("  ✓ outputs/figures/pca_loadings_heatmap.png\n")
cat("  ✓ outputs/figures/pca_biplot_pc1_pc2.png\n")
cat("  ✓ outputs/figures/pca_biplot_pc1_pc3.png\n")

cat("\n✓ Analyse PCA terminée!\n")
cat("=============================================================================\n")
