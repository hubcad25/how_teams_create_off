# Application du clustering avec k choisi (Ward)
# Basé sur les résultats de 04_explore_k.R

library(tidyverse)
library(cluster)

cat("APPLICATION DU CLUSTERING (WARD)\n\n")

# --- PARAMÈTRE À AJUSTER ---
K <- 6
# ----------------------------

# 1. CHARGEMENT ----

df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)
hc <- readRDS("data/processed/hclust_ward.rds")

score_cols <- setdiff(names(df_dim), c("team", "name"))
scores <- df_dim %>% select(all_of(score_cols)) %>% as.matrix()
rownames(scores) <- df_dim$team
d <- dist(scores)

cat("Données:", nrow(df_dim), "équipes,", length(score_cols), "dimensions\n")
cat("k choisi:", K, "\n\n")

# 2. CLUSTERING (coupe du dendrogramme) ----

clusters <- cutree(hc, k = K)

df_clustered <- df_dim %>%
  mutate(cluster = factor(clusters))

# 3. DIAGNOSTICS ----

sil <- silhouette(clusters, d)
avg_sil <- mean(sil[, 3])

cat("Silhouette moyenne:", round(avg_sil, 3), "\n")
cat("Tailles:", paste(table(clusters), collapse = "-"), "\n\n")

cat("Équipes par cluster:\n")
for (cl in sort(unique(df_clustered$cluster))) {
  teams <- df_clustered %>% filter(cluster == cl) %>% pull(team)
  cat(sprintf("  Cluster %s (%d): %s\n", cl, length(teams), paste(teams, collapse = ", ")))
}
cat("\n")

# Silhouette par équipe
sil_by_team <- tibble(
  team = df_dim$team,
  cluster = factor(clusters),
  silhouette = sil[, 3]
) %>%
  arrange(cluster, desc(silhouette))

cat("Silhouette par équipe:\n")
print(sil_by_team %>% mutate(silhouette = round(silhouette, 3)))
cat("\n")

# Équipes mal classées (silhouette négative)
misfit <- sil_by_team %>% filter(silhouette < 0)
if (nrow(misfit) > 0) {
  cat("Équipes mal classées (silhouette < 0):\n")
  print(misfit %>% mutate(silhouette = round(silhouette, 3)))
  cat("\n")
}

# 4. PROFIL DES CLUSTERS ----

cat("PROFIL DES CLUSTERS (scores moyens)\n\n")

cluster_profiles <- df_clustered %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    across(all_of(score_cols), mean),
    .groups = "drop"
  )

print(cluster_profiles %>% mutate(across(where(is.numeric) & !c(n), ~round(., 2))))
cat("\n")

# 5. SAUVEGARDE ----

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

write_csv(df_clustered, "data/processed/team_clustered.csv")
write_csv(cluster_profiles, "outputs/tables/cluster_profiles.csv")
write_csv(sil_by_team, "outputs/tables/silhouette_by_team.csv")

cat("Fichiers sauvegardés:\n")
cat("  data/processed/team_clustered.csv\n")
cat("  outputs/tables/cluster_profiles.csv\n")
cat("  outputs/tables/silhouette_by_team.csv\n")
