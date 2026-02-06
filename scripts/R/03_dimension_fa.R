# Création des dimensions via FA à 1 facteur

library(tidyverse)
library(psych)

cat("CRÉATION DES DIMENSIONS (FA)\n\n")

# 1. CHARGEMENT ----

df <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)
metric_labels <- readRDS("data/processed/metric_labels.rds")

cat("Données:", nrow(df), "équipes\n\n")

# 2. DÉFINITION DES DIMENSIONS ----

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

# 3. FONCTION FA À 1 FACTEUR ----

compute_fa_dimension <- function(df, vars, dim_name, n_factors = 1) {

  data <- df %>% select(all_of(vars))
  data_scaled <- scale(data)

  fa_result <- fa(data_scaled, nfactors = n_factors, rotate = "varimax",
                  fm = "minres", scores = "regression")

  if (n_factors == 1) {
    loadings <- fa_result$loadings[, 1]
    var_explained <- fa_result$Vaccounted["Proportion Var", 1]
    scores <- fa_result$scores[, 1]
  } else {
    loadings <- fa_result$loadings[, 1:n_factors]
    var_explained <- fa_result$Vaccounted["Cumulative Var", n_factors]
    scores <- fa_result$scores[, 1:n_factors]
  }

  list(
    scores = scores,
    loadings = loadings,
    var_explained = var_explained,
    fa_result = fa_result,
    n_factors = n_factors
  )
}

print_loadings <- function(loadings, metric_labels, dim_name, var_pct) {
  cat(sprintf("%s (%.0f%% var):\n", dim_name, var_pct * 100))

  if (is.matrix(loadings)) {
    for (f in 1:ncol(loadings)) {
      cat(sprintf("  Factor %d:\n", f))
      sorted <- sort(loadings[, f], decreasing = TRUE)
      for (i in 1:min(5, length(sorted))) {
        var <- names(sorted)[i]
        label <- metric_labels[var]
        if (is.na(label)) label <- gsub("input_", "", var)
        sign <- ifelse(sorted[i] > 0, "+", "-")
        cat(sprintf("    %s%.2f %s\n", sign, abs(sorted[i]), label))
      }
    }
  } else {
    sorted <- sort(loadings, decreasing = TRUE)
    for (i in seq_along(sorted)) {
      var <- names(sorted)[i]
      label <- metric_labels[var]
      if (is.na(label)) label <- gsub("input_", "", var)
      sign <- ifelse(sorted[i] > 0, "+", "-")
      cat(sprintf("  %s%.2f %s\n", sign, abs(sorted[i]), label))
    }
  }
  cat("\n")
}

# 4. FA PAR DIMENSION ----

cat("FA PAR DIMENSION\n\n")

results <- list()
score_list <- list()

for (dim_name in names(dimensions)) {

  vars <- dimensions[[dim_name]]

  if (dim_name == "Misc") {
    # Tester 1 et 2 facteurs pour Misc
    fa1 <- compute_fa_dimension(df, vars, dim_name, n_factors = 1)
    fa2 <- compute_fa_dimension(df, vars, dim_name, n_factors = 2)

    cat("MISC - Test 1 vs 2 facteurs:\n")
    cat(sprintf("  1 facteur: %.0f%% variance\n", fa1$var_explained * 100))
    cat(sprintf("  2 facteurs: %.0f%% variance\n", fa2$var_explained * 100))

    if ((fa2$var_explained - fa1$var_explained) > 0.15) {
      cat("  -> 2 facteurs\n\n")
      results[[dim_name]] <- fa2
      print_loadings(fa2$loadings, metric_labels, dim_name, fa2$var_explained)
      score_list[["Misc_1"]] <- fa2$scores[, 1]
      score_list[["Misc_2"]] <- fa2$scores[, 2]
    } else {
      cat("  -> 1 facteur (gain insuffisant)\n\n")
      results[[dim_name]] <- fa1
      print_loadings(fa1$loadings, metric_labels, dim_name, fa1$var_explained)
      score_list[[dim_name]] <- fa1$scores
    }

  } else {
    result <- compute_fa_dimension(df, vars, dim_name, n_factors = 1)
    results[[dim_name]] <- result
    print_loadings(result$loadings, metric_labels, dim_name, result$var_explained)
    score_list[[dim_name]] <- result$scores
  }
}

# 5. CRÉER DATAFRAME DES SCORES (standardisés) ----

score_df <- as_tibble(score_list) %>%
  mutate(across(everything(), ~as.numeric(scale(.))))

df_dimensions <- df %>%
  select(team, name) %>%
  bind_cols(score_df)

cat("SCORES PAR ÉQUIPE (aperçu)\n\n")

print(df_dimensions %>%
        mutate(across(where(is.numeric), ~round(., 2))) %>%
        arrange(desc(Volume)) %>%
        head(10))

cat("\n")

# 6. RÉSUMÉ VARIANCE ----

cat("VARIANCE EXPLIQUÉE\n\n")

var_summary <- tibble(
  Dimension = names(results),
  n_vars = sapply(dimensions, length),
  n_factors = sapply(results, function(x) x$n_factors),
  Variance_pct = sapply(results, function(x) x$var_explained) * 100
)

print(var_summary %>% mutate(Variance_pct = round(Variance_pct, 1)))

cat("\n")

# 7. SAUVEGARDE ----

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

write_csv(df_dimensions, "data/processed/team_dimension_scores.csv")
saveRDS(results, "data/processed/dimension_fa_results.rds")
saveRDS(dimensions, "data/processed/dimension_definitions.rds")

# Loadings
loadings_all <- map_dfr(names(results), function(dim_name) {
  loadings <- results[[dim_name]]$loadings
  if (is.matrix(loadings)) {
    map_dfr(1:ncol(loadings), function(f) {
      tibble(
        dimension = paste0(dim_name, "_", f),
        variable = rownames(loadings),
        loading = loadings[, f]
      )
    })
  } else {
    tibble(
      dimension = dim_name,
      variable = names(loadings),
      loading = as.numeric(loadings)
    )
  }
})
write_csv(loadings_all, "outputs/tables/dimension_loadings.csv")

cat("Fichiers sauvegardés:\n")
cat("  data/processed/team_dimension_scores.csv\n")
cat("  data/processed/dimension_fa_results.rds\n")
cat("  data/processed/dimension_definitions.rds\n")
cat("  outputs/tables/dimension_loadings.csv\n")
