# Hierarchical clustering (Ward D2) for k selection
# Computes dendrogram and saves for use in clustering

library(tidyverse)
library(cluster)

cat("HIERARCHICAL CLUSTERING (WARD D2)\n\n")

# Load dimension scores
df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)

score_cols <- setdiff(names(df_dim), c("team", "name"))
scores <- df_dim %>% select(all_of(score_cols)) %>% as.matrix()
rownames(scores) <- df_dim$team

cat("Data:", nrow(df_dim), "teams,", length(score_cols), "dimensions\n")
cat("Dimensions:", paste(score_cols, collapse = ", "), "\n\n")

# Compute distance matrix
d <- dist(scores)

# Hierarchical clustering with Ward.D2
hc <- hclust(d, method = "ward.D2")

# Team order from dendrogram
team_order <- hc$labels[hc$order]

cat("Dendrogram order:\n")
cat(paste(team_order, collapse = " → "), "\n\n")

# SILHOUETTE ANALYSIS FOR K SELECTION
k_range <- 2:8

sil_results <- tibble(
  k = k_range,
  silhouette = NA_real_,
  sizes = NA_character_
)

for (i in seq_along(k_range)) {
  k <- k_range[i]
  clusters <- cutree(hc, k = k)
  sil <- silhouette(clusters, d)
  sil_results$silhouette[i] <- mean(sil[, 3])
  sil_results$sizes[i] <- paste(sort(table(clusters)), collapse = "-")
}

cat("Silhouette by k:\n\n")
print(sil_results %>% mutate(silhouette = round(silhouette, 3)))
cat("\n")

# Preview for k = 3, 4, 5, 6
k_candidates <- c(3, 4, 5, 6)

for (k in k_candidates) {
  clusters <- cutree(hc, k = k)
  cat(sprintf("--- k = %d (silhouette = %.3f) ---\n",
              k, sil_results$silhouette[sil_results$k == k]))

  for (cl in sort(unique(clusters))) {
    teams <- names(clusters[clusters == cl])
    cat(sprintf("  Cluster %d (%d): %s\n", cl, length(teams), paste(teams, collapse = ", ")))
  }
  cat("\n")
}

# SAVE RESULTS
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

saveRDS(hc, "data/processed/hclust_ward.rds")
write_csv(sil_results, "outputs/tables/hclust_silhouette_by_k.csv")

cat("Files saved:\n")
cat("  data/processed/hclust_ward.rds\n")
cat("  outputs/tables/hclust_silhouette_by_k.csv\n")
