# Clustering sur les dimensions FA

library(tidyverse)
library(cluster)
library(clessnize)

cat("CLUSTERING SUR DIMENSIONS FA\n\n")

# 1. CHARGEMENT ----

df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)

score_cols <- setdiff(names(df_dim), c("team", "name"))
scores <- df_dim %>% select(all_of(score_cols)) %>% as.matrix()

cat("Données:", nrow(df_dim), "équipes,", length(score_cols), "dimensions\n")
cat("Dimensions:", paste(score_cols, collapse = ", "), "\n\n")

# 2. GRID SEARCH: SILHOUETTE PAR K ----

cat("SÉLECTION DU NOMBRE DE CLUSTERS\n\n")

k_range <- 2:8

silhouette_results <- tibble(
  k = k_range,
  silhouette = NA_real_,
  sizes = NA_character_
)

set.seed(42)

for (i in seq_along(k_range)) {
  k <- k_range[i]
  km <- kmeans(scores, centers = k, nstart = 25)
  sil <- silhouette(km$cluster, dist(scores))
  silhouette_results$silhouette[i] <- mean(sil[, 3])
  silhouette_results$sizes[i] <- paste(sort(table(km$cluster)), collapse = "-")
}

cat("Silhouette par k:\n\n")
print(silhouette_results %>% mutate(silhouette = round(silhouette, 3)))

cat("\n")

best_k <- silhouette_results %>%
  filter(silhouette == max(silhouette)) %>%
  pull(k)

cat("Meilleur k:", best_k, "(silhouette =",
    round(max(silhouette_results$silhouette), 3), ")\n\n")

# 3. VISUALISATION SILHOUETTE ----

p_sil <- ggplot(silhouette_results, aes(x = k, y = silhouette)) +
  geom_line(linewidth = 1, color = "#2c3e50") +
  geom_point(size = 3, color = "#2c3e50") +
  geom_point(data = silhouette_results %>% filter(k == best_k),
             size = 5, color = "#e74c3c") +
  geom_hline(yintercept = 0.25, linetype = "dashed", color = "#95a5a6") +
  annotate("text", x = 7.5, y = 0.27, label = "seuil 0.25", color = "#95a5a6", size = 3) +
  scale_x_continuous(breaks = k_range) +
  labs(
    title = "Silhouette par nombre de clusters",
    subtitle = sprintf("Dimensions: %s", paste(score_cols, collapse = ", ")),
    x = "Nombre de clusters (k)",
    y = "Silhouette moyenne"
  ) +
  theme_clean_light() +
  theme(plot.title = element_text(face = "bold"))

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("outputs/figures/clustering_silhouette.png", p_sil, width = 8, height = 5, dpi = 150)

# 4. CLUSTERING FINAL ----

cat("CLUSTERING FINAL (k =", best_k, ")\n\n")

set.seed(42)
km_final <- kmeans(scores, centers = best_k, nstart = 50)

df_clustered <- df_dim %>%
  mutate(cluster = factor(km_final$cluster))

sil_final <- silhouette(km_final$cluster, dist(scores))
avg_sil <- mean(sil_final[, 3])

cat("Silhouette:", round(avg_sil, 3), "\n")
cat("Tailles:", paste(table(km_final$cluster), collapse = "-"), "\n\n")

cat("Équipes par cluster:\n")
for (cl in sort(unique(df_clustered$cluster))) {
  teams <- df_clustered %>% filter(cluster == cl) %>% pull(team)
  cat(sprintf("  Cluster %s: %s\n", cl, paste(teams, collapse = ", ")))
}

cat("\n")

# 5. PROFIL DES CLUSTERS ----

cat("PROFIL DES CLUSTERS\n\n")

cluster_profiles <- df_clustered %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    across(all_of(score_cols), mean),
    .groups = "drop"
  )

print(cluster_profiles %>% mutate(across(where(is.numeric) & !c(n), ~round(., 2))))

cat("\n")

# 6. SAUVEGARDE ----

write_csv(df_clustered, "data/processed/team_clustered.csv")
write_csv(cluster_profiles, "outputs/tables/cluster_profiles.csv")
write_csv(silhouette_results, "outputs/tables/silhouette_by_k.csv")
saveRDS(km_final, "data/processed/kmeans_result.rds")

cat("Fichiers sauvegardés:\n")
cat("  data/processed/team_clustered.csv\n")
cat("  outputs/tables/cluster_profiles.csv\n")
cat("  outputs/tables/silhouette_by_k.csv\n")
cat("  outputs/figures/clustering_silhouette.png\n")
cat("  data/processed/kmeans_result.rds\n")
