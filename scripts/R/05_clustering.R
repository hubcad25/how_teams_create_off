# =============================================================================
# K-means clustering (2 PC, k=4)
# =============================================================================

library(tidyverse)
library(cluster)
library(clessnize)

cat("=============================================================================\n")
cat("K-MEANS CLUSTERING\n")
cat("=============================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. CHARGEMENT
# -----------------------------------------------------------------------------

pca_result <- readRDS("data/processed/pca_result.rds")
df <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)
metric_labels <- readRDS("data/processed/metric_labels.rds")

n_pc <- 3
n_clusters <- 6

scores <- pca_result$x[, 1:n_pc]
variance_pct <- (pca_result$sdev^2) / sum(pca_result$sdev^2) * 100

cat(sprintf("Config: %d PC, k=%d\n", n_pc, n_clusters))
cat("Variance capturée:", round(sum(variance_pct[1:n_pc]), 1), "%\n\n")

# -----------------------------------------------------------------------------
# 2. K-MEANS
# -----------------------------------------------------------------------------

set.seed(42)
km <- kmeans(scores, centers = n_clusters, nstart = 50)

# Ajouter clusters au dataframe
df_clustered <- df %>%
  mutate(
    cluster = factor(km$cluster),
    PC1 = pca_result$x[, 1],
    PC2 = pca_result$x[, 2],
    PC3 = pca_result$x[, 3]
  )

# Silhouette
sil <- silhouette(km$cluster, dist(scores))
avg_sil <- mean(sil[, 3])

cat("Résultats:\n")
cat("  Silhouette moyenne:", round(avg_sil, 3), "\n")
cat("  Équipes par cluster:\n")
table(km$cluster) %>% print()

cat("\n")

# -----------------------------------------------------------------------------
# 3. CENTRES DES CLUSTERS
# -----------------------------------------------------------------------------

centers <- as_tibble(km$centers) %>%
  mutate(cluster = factor(1:n_clusters), .before = 1)

cat("Centres des clusters (PC space):\n")
print(centers %>% mutate(across(where(is.numeric), ~round(., 2))))

cat("\n")

# -----------------------------------------------------------------------------
# 4. ÉQUIPES PAR CLUSTER
# -----------------------------------------------------------------------------

cat("=============================================================================\n")
cat("ÉQUIPES PAR CLUSTER\n")
cat("=============================================================================\n\n")

for (cl in 1:n_clusters) {
  teams <- df_clustered %>%
    filter(cluster == cl) %>%
    arrange(PC1) %>%
    pull(team)

  cat(sprintf("Cluster %d (%d équipes): %s\n", cl, length(teams), paste(teams, collapse = ", ")))
}

cat("\n")

# -----------------------------------------------------------------------------
# 5. VISUALISATION: SCATTER PC1 vs PC2
# -----------------------------------------------------------------------------

# Palette distincte
cluster_colors <- c("1" = "#e74c3c", "2" = "#3498db", "3" = "#27ae60",
                    "4" = "#9b59b6", "5" = "#f39c12", "6" = "#1abc9c",
                    "7" = "#e91e63", "8" = "#795548")

# PC1 vs PC2
p_scatter_12 <- ggplot(df_clustered, aes(x = PC1, y = PC2, color = cluster)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_point(size = 4, alpha = 0.8) +
  geom_text(aes(label = team), nudge_y = 0.35, size = 3, show.legend = FALSE) +
  scale_color_manual(values = cluster_colors) +
  labs(
    title = "Clusters d'équipes NHL (5v5 offense)",
    subtitle = sprintf("K-means: %d PC (%.0f%% var), k=%d | Silhouette: %.2f",
                       n_pc, sum(variance_pct[1:n_pc]), n_clusters, avg_sil),
    x = sprintf("PC1: Volume (%.1f%%)", variance_pct[1]),
    y = sprintf("PC2: Qualité (%.1f%%)", variance_pct[2]),
    color = "Cluster"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

# PC1 vs PC3
p_scatter_13 <- ggplot(df_clustered, aes(x = PC1, y = PC3, color = cluster)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.3) +
  geom_point(size = 4, alpha = 0.8) +
  geom_text(aes(label = team), nudge_y = 0.25, size = 3, show.legend = FALSE) +
  scale_color_manual(values = cluster_colors) +
  labs(
    title = "Clusters d'équipes NHL (5v5 offense)",
    subtitle = sprintf("K-means: %d PC (%.0f%% var), k=%d | Silhouette: %.2f",
                       n_pc, sum(variance_pct[1:n_pc]), n_clusters, avg_sil),
    x = sprintf("PC1: Volume (%.1f%%)", variance_pct[1]),
    y = sprintf("PC3: Précision/Physique (%.1f%%)", variance_pct[3]),
    color = "Cluster"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("outputs/figures/clusters_pc1_pc2.png", p_scatter_12, width = 12, height = 9, dpi = 150)
ggsave("outputs/figures/clusters_pc1_pc3.png", p_scatter_13, width = 12, height = 9, dpi = 150)

# -----------------------------------------------------------------------------
# 6. SAUVEGARDE
# -----------------------------------------------------------------------------

# Données avec clusters
write_csv(df_clustered, "data/processed/team_metrics_clustered.csv")

# Résumé clustering
cluster_summary <- df_clustered %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    PC1_mean = mean(PC1),
    PC2_mean = mean(PC2),
    teams = paste(team, collapse = ", "),
    .groups = "drop"
  )

write_csv(cluster_summary, "outputs/tables/cluster_summary.csv")

# Objet kmeans
saveRDS(km, "data/processed/kmeans_result.rds")

cat("=============================================================================\n")
cat("FICHIERS SAUVEGARDÉS\n")
cat("=============================================================================\n\n")
cat("✓ data/processed/team_metrics_clustered.csv\n")
cat("✓ data/processed/kmeans_result.rds\n")
cat("✓ outputs/tables/cluster_summary.csv\n")
cat("✓ outputs/figures/clusters_pc1_pc2.png\n")
cat("✓ outputs/figures/clusters_pc1_pc3.png\n")
