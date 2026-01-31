# =============================================================================
# Sélection du nombre de PC et de clusters (silhouette grid search)
# =============================================================================

library(tidyverse)
library(cluster)

cat("=============================================================================\n")
cat("GRID SEARCH: SILHOUETTE PAR PC × K\n")
cat("=============================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. CHARGEMENT
# -----------------------------------------------------------------------------

pca_result <- readRDS("data/processed/pca_result.rds")
scores <- pca_result$x
variance_pct <- (pca_result$sdev^2) / sum(pca_result$sdev^2) * 100
variance_cumul <- cumsum(variance_pct)

cat("Données:", nrow(scores), "équipes,", ncol(scores), "PC\n\n")

# -----------------------------------------------------------------------------
# 2. GRID SEARCH
# -----------------------------------------------------------------------------

pc_range <- 2:8
k_range <- 2:8

results <- expand_grid(n_pc = pc_range, k = k_range) %>%
  mutate(
    variance = variance_cumul[n_pc],
    silhouette = NA_real_
  )

set.seed(42)

for (i in 1:nrow(results)) {
  data_subset <- scores[, 1:results$n_pc[i]]
  km <- kmeans(data_subset, centers = results$k[i], nstart = 25)
  sil <- silhouette(km$cluster, dist(data_subset))
  results$silhouette[i] <- mean(sil[, 3])
}

# -----------------------------------------------------------------------------
# 3. RÉSULTATS
# -----------------------------------------------------------------------------

# Table pivot
silhouette_matrix <- results %>%
  select(n_pc, k, silhouette) %>%
  pivot_wider(names_from = k, values_from = silhouette, names_prefix = "k=")

cat("Silhouette (lignes = PC, colonnes = k):\n\n")
print(silhouette_matrix %>% mutate(across(where(is.numeric), ~round(., 3))))

# Meilleure combinaison
best <- results %>% filter(silhouette == max(silhouette))

cat("\n=============================================================================\n")
cat("MEILLEURE COMBINAISON:\n")
cat(sprintf("  %d PC (%.1f%% variance), k=%d clusters\n",
            best$n_pc, best$variance, best$k))
cat(sprintf("  Silhouette = %.3f\n", best$silhouette))
cat("=============================================================================\n\n")

# Top 5
cat("Top 5 combinaisons:\n")
results %>%
  arrange(desc(silhouette)) %>%
  head(5) %>%
  mutate(across(where(is.numeric), ~round(., 3))) %>%
  print()

# -----------------------------------------------------------------------------
# 4. HEATMAP
# -----------------------------------------------------------------------------

library(clessnize)

p <- ggplot(results, aes(x = factor(n_pc), y = factor(k), fill = silhouette)) +

  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", silhouette)), size = 3.5) +
  scale_fill_gradient2(
    low = "#c0392b", mid = "#f5f5f5", high = "#27ae60",
    midpoint = 0.25, limits = c(0.1, 0.45)
  ) +
  labs(
    title = "Silhouette par nombre de PC et de clusters",
    subtitle = sprintf("Meilleur: %d PC, k=%d (sil=%.3f)", best$n_pc, best$k, best$silhouette),
    x = "Nombre de PC",
    y = "Nombre de clusters (k)",
    fill = "Silhouette"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("outputs/figures/silhouette_heatmap.png", p, width = 8, height = 6, dpi = 150)

# -----------------------------------------------------------------------------
# 5. SAUVEGARDE
# -----------------------------------------------------------------------------

dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)
write_csv(results, "outputs/tables/silhouette_grid.csv")

cat("\n✓ outputs/figures/silhouette_heatmap.png\n")
cat("✓ outputs/tables/silhouette_grid.csv\n")
