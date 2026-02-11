# Apply 2025-26 clustering model to historical seasons
# Load model components and assign historical teams to clusters

library(tidyverse)
library(psych)

cat("APPLY 2025-26 MODEL TO HISTORICAL SEASONS\n\n")

# --- PARAMETERS ---
POWER <- 1.15  # Same as 03_analysis_dimension_scores.R
# ---------------

# 1. LOAD 2025-26 MODEL ----

cat("Loading 2025-26 model...\n")

# Dimensions definitions (FA groupings)
dimensions <- readRDS("data/processed/dimension_definitions.rds")

# FA results (loadings)
fa_results_2025 <- readRDS("data/processed/dimension_fa_results.rds")

# Clustered teams 2025-26
df_2025 <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE)

# Extract centroids (mean scores per cluster)
score_cols <- setdiff(names(df_2025), c("team", "name", "cluster"))
centroids_2025 <- df_2025 %>%
  group_by(cluster) %>%
  summarise(across(all_of(score_cols), mean), .groups = "drop")

cat("  Model loaded:", nrow(centroids_2025), "clusters,", length(score_cols), "dimensions\n\n")

# 2. FUNCTION TO COMPUTE FA SCORES ----

compute_fa_scores <- function(df_new, fa_results, dimensions) {

  score_list <- list()

  for (dim_name in names(dimensions)) {
    vars <- dimensions[[dim_name]]
    result <- fa_results[[dim_name]]

    # Get data and standardize
    data <- df_new %>% select(all_of(vars))

    # Handle 2-factor Misc dimension
    if (result$n_factors == 2) {
      # For 2 factors, compute scores using loadings matrix
      loadings_mat <- result$loadings
      data_scaled <- scale(data, center = TRUE, scale = TRUE)
      scores <- data_scaled %*% loadings_mat

      score_list[["RecoveryPossession"]] <- as.vector(scores[, 1])
      score_list[["PuckExchanges"]] <- as.vector(scores[, 2])
    } else {
      # 1 factor: use regression scoring method
      loadings_vec <- result$loadings
      data_scaled <- scale(data, center = TRUE, scale = TRUE)

      # Regression scoring: scores = data * loadings
      scores <- data_scaled %*% loadings_vec
      score_list[[dim_name]] <- as.vector(scores)
    }
  }

  # Accentuate scores
  accentuate <- function(x) sign(x) * abs(x)^POWER

  score_df <- as_tibble(score_list) %>%
    mutate(across(everything(), ~accentuate(as.numeric(scale(.)))))

  return(score_df)
}

# 3. FUNCTION TO ASSIGN TO CLUSTERS ----

assign_to_clusters <- function(scores, centroids) {

  # Compute distance to each centroid
  distances <- sapply(1:nrow(centroids), function(k) {
    centroid <- centroids %>% slice(k) %>% select(all_of(score_cols))
    rowSums((scores - as.matrix(centroid))^2)
  })

  # Assign to nearest centroid
  cluster_assigned <- apply(distances, 1, which.min)
  min_distance <- apply(distances, 1, min)

  tibble(
    cluster = factor(cluster_assigned),
    distance_to_centroid = sqrt(min_distance)
  )
}

# 4. APPLY TO EACH HISTORICAL SEASON ----

cat("Applying to historical seasons...\n\n")

seasons <- c("2020", "2021", "2022", "2023", "2024")
all_clustered <- list()

for (season in seasons) {
  cat(paste0("Season ", season, "-", as.integer(season)+1, ":\n"))

  # Load cleaned data
  df_hist <- read_csv(paste0("data/cleaned/team_data_clean_", season, ".csv"),
                      show_col_types = FALSE)

  cat("  ", nrow(df_hist), "teams\n")

  # Compute FA scores
  scores_hist <- compute_fa_scores(df_hist, fa_results_2025, dimensions)

  # Assign to clusters
  cluster_assignments <- assign_to_clusters(scores_hist, centroids_2025)

  # Combine results
  df_result <- df_hist %>%
    select(team, name, season_year, games_played) %>%
    bind_cols(scores_hist) %>%
    bind_cols(cluster_assignments)

  # Summary
  cluster_summary <- df_result %>%
    count(cluster) %>%
    arrange(cluster)
  cat("  Distribution:", paste(cluster_summary$n, collapse = "-"), "\n\n")

  all_clustered[[season]] <- df_result
}

# 5. COMBINE ALL SEASONS ----

df_all_seasons <- bind_rows(all_clustered)

cat("===================================\n")
cat("TOTAL:", nrow(df_all_seasons), "team-seasons\n\n")

# 6. ADD 2025-26 FOR COMPARISON ----

# Compute actual distance to centroid for 2025-26 teams
dist_2025 <- assign_to_clusters(
  df_2025 %>% select(all_of(score_cols)),
  centroids_2025
)

df_2025_renamed <- df_2025 %>%
  select(team, name, all_of(score_cols), cluster) %>%
  mutate(season_year = "2025-2026") %>%
  mutate(cluster = as.factor(cluster)) %>%
  mutate(distance_to_centroid = dist_2025$distance_to_centroid)

df_complete <- bind_rows(df_all_seasons, df_2025_renamed) %>%
  mutate(season_year = factor(season_year))

# 7. SAVE DATA ----

cat("Saving results...\n")

dir.create("data/historical", showWarnings = FALSE, recursive = TRUE)

# Full dataset with clusters
write_csv(df_complete, "data/historical/all_seasons_with_clusters.csv")
cat("  data/historical/all_seasons_with_clusters.csv\n")

# Summary table
cluster_summary_season <- df_complete %>%
  group_by(season_year, cluster) %>%
  summarise(
    n = n(),
    avg_distance = mean(distance_to_centroid),
    .groups = "drop"
  ) %>%
  arrange(season_year, cluster)

write_csv(cluster_summary_season, "data/historical/cluster_distribution_by_season.csv")
cat("  data/historical/cluster_distribution_by_season.csv\n\n")

# 8. DISPLAY SUMMARY ----

cat("CLUSTER DISTRIBUTION BY SEASON\n\n")
print(cluster_summary_season %>%
        mutate(avg_distance = round(avg_distance, 3)))

cat("\n")

# Cluster stability: which teams stay in same cluster?
cat("CLUSTER STABILITY (2020-24 vs 2025-26)\n\n")

# Get teams with data in multiple seasons
team_seasons <- df_complete %>%
  filter(season_year != "2025-2026") %>%
  group_by(team) %>%
  filter(n() > 1) %>%
  pull(team) %>%
  unique()

cat("Teams in multiple seasons:", length(team_seasons), "\n\n")

# Compare first season vs 2025-26
stability <- df_complete %>%
  filter(team %in% team_seasons) %>%
  select(team, season_year, cluster) %>%
  arrange(team, season_year) %>%
  group_by(team) %>%
  mutate(
    first_cluster = first(cluster),
    last_cluster = last(cluster),
    n_seasons = n()
  ) %>%
  ungroup() %>%
  filter(season_year == "2025-2026") %>%
  mutate(stable = (first_cluster == cluster))

cat("Stable teams (same cluster in 2025-26 as at start):\n",
    sum(stability$stable), "/",
    nrow(stability),
    sprintf("(%.0f%%)", mean(stability$stable) * 100), "\n\n")

cat("Script complete.\n")
