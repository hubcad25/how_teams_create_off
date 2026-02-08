# Hierarchical clustering (Ward) with k=6
# Assign teams to 6 offensive archetypes

library(tidyverse)
library(cluster)

cat("HIERARCHICAL CLUSTERING (WARD)\n\n")

# --- PARAMETER TO ADJUST ---
K <- 6
# ----------------------------

# 1. LOAD DATA ----

df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)
hc <- readRDS("data/processed/hclust_ward.rds")

all_dims <- setdiff(names(df_dim), c("team", "name"))
score_cols <- setdiff(all_dims, "Finishing")  # Finishing excluded from clustering (intermediate var)
scores <- df_dim %>% select(all_of(score_cols)) %>% as.matrix()
rownames(scores) <- df_dim$team
d <- dist(scores)

cat("Data:", nrow(df_dim), "teams,", length(score_cols), "dimensions\n")
cat("k selected:", K, "\n\n")

# 2. CLUSTERING (dendrogram cut) ----

clusters <- cutree(hc, k = K)

df_clustered <- df_dim %>%
  mutate(cluster = factor(clusters))

# 3. DIAGNOSTICS ----

sil <- silhouette(clusters, d)
avg_sil <- mean(sil[, 3])

cat("Average silhouette:", round(avg_sil, 3), "\n")
cat("Cluster sizes:", paste(table(clusters), collapse = "-"), "\n\n")

cat("Teams per cluster:\n")
for (cl in sort(unique(df_clustered$cluster))) {
  teams <- df_clustered %>% filter(cluster == cl) %>% pull(team)
  cat(sprintf("  Cluster %s (%d): %s\n", cl, length(teams), paste(teams, collapse = ", ")))
}
cat("\n")

# Silhouette by team
sil_by_team <- tibble(
  team = df_dim$team,
  cluster = factor(clusters),
  silhouette = sil[, 3]
) %>%
  arrange(cluster, desc(silhouette))

cat("Silhouette by team:\n")
print(sil_by_team %>% mutate(silhouette = round(silhouette, 3)))
cat("\n")

# Poorly fitted teams (negative silhouette)
misfit <- sil_by_team %>% filter(silhouette < 0)
if (nrow(misfit) > 0) {
  cat("Poorly fitted teams (silhouette < 0):\n")
  print(misfit %>% mutate(silhouette = round(silhouette, 3)))
  cat("\n")
}

# 3b. REFINEMENT: reassign negative silhouettes + singletons ----

# Reassign negative-silhouette teams to their neighbor cluster
neg_idx <- which(sil[, 3] < 0)
if (length(neg_idx) > 0) {
  for (i in neg_idx) {
    old_cl <- clusters[i]
    new_cl <- sil[i, 2]  # neighbor cluster
    cat(sprintf("Reassign %s: cluster %d -> %d (silhouette was %.3f)\n",
                df_dim$team[i], old_cl, new_cl, sil[i, 3]))
    clusters[i] <- new_cl
  }
}

# Reassign singletons to their neighbor cluster
singleton_cls <- as.integer(names(which(table(clusters) == 1)))
if (length(singleton_cls) > 0) {
  for (cl in singleton_cls) {
    i <- which(clusters == cl)
    new_cl <- sil[i, 2]  # neighbor cluster
    cat(sprintf("Reassign singleton %s: cluster %d -> %d\n",
                df_dim$team[i], cl, new_cl))
    clusters[i] <- new_cl
  }
}

# Renumber clusters sequentially
clusters <- as.integer(factor(clusters, levels = sort(unique(clusters))))

df_clustered <- df_dim %>%
  mutate(cluster = factor(clusters))

cat(sprintf("\nAfter refinement: %d clusters\n", length(unique(clusters))))
cat("Cluster sizes:", paste(table(clusters), collapse = "-"), "\n\n")

cat("Teams per cluster (refined):\n")
for (cl in sort(unique(df_clustered$cluster))) {
  teams <- df_clustered %>% filter(cluster == cl) %>% pull(team)
  cat(sprintf("  Cluster %s (%d): %s\n", cl, length(teams), paste(teams, collapse = ", ")))
}
cat("\n")

# 4. CLUSTER PROFILES ----

cat("CLUSTER PROFILES (mean scores)\n\n")

cluster_profiles <- df_clustered %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    across(all_of(score_cols), mean),
    .groups = "drop"
  )

print(cluster_profiles %>% mutate(across(where(is.numeric) & !c(n), ~round(., 2))))
cat("\n")

# 5. SAVE DATA ----

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

write_csv(df_clustered, "data/processed/team_clustered.csv")
write_csv(cluster_profiles, "outputs/tables/cluster_profiles.csv")
write_csv(sil_by_team, "outputs/tables/silhouette_by_team.csv")

cat("Files saved:\n")
cat("  data/processed/team_clustered.csv\n")
cat("  outputs/tables/cluster_profiles.csv\n")
cat("  outputs/tables/silhouette_by_team.csv\n")
