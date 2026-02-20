# Factor Analysis: Create 7 orthogonal dimensions
# One factor per dimension (confirmatory FA)
# Pool: 159 historical team-seasons + 2025-26 (~191 total)

library(tidyverse)
library(psych)

cat("FACTOR ANALYSIS: DIMENSION CREATION\n\n")

# 1. LOAD DATA ----

# Historical team-seasons (2020-21 to 2024-25)
df_hist <- read_csv("data/cleaned/all_seasons_clean.csv", show_col_types = FALSE) %>%
  rename(season = season_year) %>%
  mutate(season = as.character(season))

# Current season (2025-26)
df_latest <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE) %>%
  mutate(season = as.character(season))

# Combine into full pool
df <- bind_rows(df_hist, df_latest)

metric_labels <- readRDS("data/processed/metric_labels.rds")

cat("Historical team-seasons:", nrow(df_hist), "\n")
cat("Current season (2025-26):", nrow(df_latest), "\n")
cat("Total pool:", nrow(df), "team-seasons\n\n")

# 1b. NORMALIZE TK/GV BY ERA (rupture de comptage 2024-25) ----

era_a_seasons <- c("2020-2021", "2021-2022", "2022-2023", "2023-2024")
era_b_seasons <- c("2024-2025", "2025")

tk_gv_vars <- c("input_takeaways_per60", "input_giveaways_per60", "input_takeaway_giveaway_ratio")

normalize_era <- function(df, vars, era_a, era_b) {
  df_out <- df
  for (v in vars) {
    idx_a <- df$season %in% era_a
    idx_b <- df$season %in% era_b

    mean_a <- mean(df[[v]][idx_a], na.rm = TRUE)
    sd_a   <- sd(df[[v]][idx_a],   na.rm = TRUE)
    mean_b <- mean(df[[v]][idx_b], na.rm = TRUE)
    sd_b   <- sd(df[[v]][idx_b],   na.rm = TRUE)

    df_out[[v]][idx_a] <- (df[[v]][idx_a] - mean_a) / sd_a
    df_out[[v]][idx_b] <- (df[[v]][idx_b] - mean_b) / sd_b
  }
  df_out
}

df <- normalize_era(df, tk_gv_vars, era_a_seasons, era_b_seasons)

cat("TK/GV normalized by era (era A:", sum(df$season %in% era_a_seasons),
    "team-seasons; era B:", sum(df$season %in% era_b_seasons), "team-seasons)\n\n")

# 2. DEFINE DIMENSIONS ----

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

  Finishing = c(
    "output_shooting_pct_vs_expected",
    "output_goals_above_expected",
    "output_HD_goals_vs_xG",
    "output_MD_goals_vs_xG",
    "output_LD_goals_vs_xG"
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

# Dimension names for output (English)
dim_names <- c(
  "Volume" = "Volume",
  "Qualite" = "Quality",
  "Penetration" = "Penetration",
  "Rebonds" = "Rebounds",
  "Finishing" = "Finishing",
  "Misc_1" = "Recovery+Possession",
  "Misc_2" = "Puck exchanges"
)

# 3. FA FUNCTION (1 FACTOR) ----

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
        if (is.na(label)) label <- gsub("^(input|output)_", "", var)
        sign <- ifelse(sorted[i] > 0, "+", "-")
        cat(sprintf("    %s%.2f %s\n", sign, abs(sorted[i]), label))
      }
    }
  } else {
    sorted <- sort(loadings, decreasing = TRUE)
    for (i in seq_along(sorted)) {
      var <- names(sorted)[i]
      label <- metric_labels[var]
      if (is.na(label)) label <- gsub("^(input|output)_", "", var)
      sign <- ifelse(sorted[i] > 0, "+", "-")
      cat(sprintf("  %s%.2f %s\n", sign, abs(sorted[i]), label))
    }
  }
  cat("\n")
}

# 4. FA PER DIMENSION ----

cat("FACTOR ANALYSIS BY DIMENSION\n\n")

results <- list()
score_list <- list()

for (dim_name in names(dimensions)) {

  vars <- dimensions[[dim_name]]

  if (dim_name == "Misc") {
    # Test 1 vs 2 factors for Misc
    fa1 <- compute_fa_dimension(df, vars, dim_name, n_factors = 1)
    fa2 <- compute_fa_dimension(df, vars, dim_name, n_factors = 2)

    cat("MISC - Test 1 vs 2 factors:\n")
    cat(sprintf("  1 factor: %.0f%% variance\n", fa1$var_explained * 100))
    cat(sprintf("  2 factors: %.0f%% variance\n", fa2$var_explained * 100))

    if ((fa2$var_explained - fa1$var_explained) > 0.15) {
      cat("  -> 2 factors\n\n")
      results[[dim_name]] <- fa2
      print_loadings(fa2$loadings, metric_labels, dim_name, fa2$var_explained)
      score_list[["RecoveryPossession"]] <- fa2$scores[, 1]
      score_list[["PuckExchanges"]] <- fa2$scores[, 2]
    } else {
      cat("  -> 1 factor (insufficient gain)\n\n")
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

# 4b. DIAGNOSTICS TK/GV NORMALISATION (console only) ----

cat("DIAGNOSTICS: TK/GV NORMALISATION\n\n")

# 1. Corrélations inter-items TK/GV intra-ère après normalisation
for (era_label in c("A", "B")) {
  era_seasons <- if (era_label == "A") era_a_seasons else era_b_seasons
  df_era <- df %>% filter(season %in% era_seasons) %>% select(all_of(tk_gv_vars))
  cat(sprintf("Correlations TK/GV (era %s, n=%d):\n", era_label, nrow(df_era)))
  print(round(cor(df_era, use = "complete.obs"), 3))
  cat("\n")
}

# 2. Variance expliquée par Misc_1 (RecoveryPossession) après normalisation
#    (déjà capturé dans results ci-dessus — on l'affiche ici explicitement)
if (!is.null(results[["Misc"]])) {
  misc_result <- results[["Misc"]]
  if (misc_result$n_factors == 2) {
    ss <- colSums(misc_result$loadings^2)
    n_misc_vars <- length(dimensions[["Misc"]])
    cat(sprintf("Misc_1 (RecoveryPossession) variance: %.1f%%\n", ss[1] / n_misc_vars * 100))
    cat(sprintf("Misc_2 (PuckExchanges)      variance: %.1f%%\n\n", ss[2] / n_misc_vars * 100))
  } else {
    cat(sprintf("Misc (1 factor) variance: %.1f%%\n\n",
                misc_result$var_explained * 100))
  }
}

# 3. Distribution des scores RecoveryPossession par ère (pré-accentuation)
#    On reconstruire les scores bruts depuis score_list avant accentuation
if ("RecoveryPossession" %in% names(score_list)) {
  rp_raw <- scale(as.numeric(score_list[["RecoveryPossession"]]))
  for (era_label in c("A", "B")) {
    era_seasons <- if (era_label == "A") era_a_seasons else era_b_seasons
    idx <- df$season %in% era_seasons
    rp_era <- rp_raw[idx]
    cat(sprintf("RecoveryPossession scores era %s (n=%d): mean=%.3f  SD=%.3f\n",
                era_label, sum(idx), mean(rp_era), sd(rp_era)))
    if (era_label == "B" && sd(rp_era) < 0.3) {
      cat("  NOTE: SD era B < 0.3 — dimension discrimine peu les equipes ere B (finding, pas un bug)\n")
    }
  }
  cat("\n")
}

# 5. CREATE SCORE DATAFRAME (standardized + accentuated) ----

# Power transformation to accentuate extremes
# sign(x) * |x|^p with p > 1
POWER <- 1.15

accentuate <- function(x) sign(x) * abs(x)^POWER

score_df <- as_tibble(score_list) %>%
  mutate(across(everything(), ~accentuate(as.numeric(scale(.)))))

df_dimensions <- df %>%
  select(team, name, season) %>%
  bind_cols(score_df)

cat("TEAM SCORES (preview)\n\n")

print(df_dimensions %>%
        mutate(across(where(is.numeric), ~round(., 2))) %>%
        arrange(desc(Volume)) %>%
        head(10))

cat("\n")

# 6. VARIANCE SUMMARY ----

cat("VARIANCE EXPLAINED\n\n")

var_summary <- tibble(
  Dimension = names(results),
  n_vars = sapply(dimensions, length),
  n_factors = sapply(results, function(x) x$n_factors),
  Variance_pct = sapply(results, function(x) x$var_explained) * 100
)

print(var_summary %>% mutate(Variance_pct = round(Variance_pct, 1)))

cat("\n")

# 7. SAVE DATA ----

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed/historical_model", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

write_csv(df_dimensions, "data/processed/team_dimension_scores.csv")

# FA models saved to historical_model/ (trained on full 191-team-season pool)
saveRDS(results, "data/processed/historical_model/dimension_fa_results.rds")
saveRDS(dimensions, "data/processed/historical_model/dimension_definitions.rds")

# Loadings table
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

# Dimension summary table (for README)
dimension_summary <- map_dfr(names(results), function(dim_name) {
  result <- results[[dim_name]]
  vars <- dimensions[[dim_name]]
  n_vars <- length(vars)
  data <- df %>% select(all_of(vars))
  data_scaled <- scale(data)

  # Cronbach's alpha (with check.keys for items with negative correlations)
  alpha_result <- psych::alpha(data_scaled, check.keys = TRUE)
  cronbach_alpha <- round(alpha_result$total$std.alpha, 3)

  if (result$n_factors == 1) {
    # Single factor dimension
    var_pct <- round(result$var_explained * 100, 1)
    eigen <- round(result$var_explained * n_vars, 2)

    tibble(
      dimension = dim_name,
      dimension_label = dim_name,
      n_vars = n_vars,
      n_factors = 1,
      variance_pct = var_pct,
      eigenvalue = eigen,
      cronbach_alpha = cronbach_alpha
    )
  } else {
    # Misc with 2 factors - calculate variance per factor from loadings
    loadings_mat <- result$loadings

    # Sum of squared loadings for each factor = variance explained
    ss_loadings <- colSums(loadings_mat^2)
    var_pcts <- round(ss_loadings / n_vars * 100, 1)
    eigen_values <- round(ss_loadings, 2)

    list(
      tibble(
        dimension = "RecoveryPossession",
        dimension_label = "Recovery+Possession",
        n_vars = n_vars,
        n_factors = 2,
        variance_pct = var_pcts[1],
        eigenvalue = eigen_values[1],
        cronbach_alpha = cronbach_alpha
      ),
      tibble(
        dimension = "PuckExchanges",
        dimension_label = "Puck Exchanges",
        n_vars = n_vars,
        n_factors = 2,
        variance_pct = var_pcts[2],
        eigenvalue = eigen_values[2],
        cronbach_alpha = cronbach_alpha
      )
    )
  }
}) %>%
  # Fix dimension labels for French names
  mutate(
    dimension_label = case_when(
      dimension == "Qualite" ~ "Quality",
      dimension == "Rebonds" ~ "Rebounds",
      dimension == "Penetration" ~ "Penetration",
      dimension == "Misc" ~ "Misc",
      TRUE ~ dimension_label
    )
  )

write_csv(dimension_summary, "outputs/tables/dimension_summary.csv")

cat("Files saved:\n")
cat("  data/processed/team_dimension_scores.csv\n")
cat("  data/processed/historical_model/dimension_fa_results.rds\n")
cat("  data/processed/historical_model/dimension_definitions.rds\n")
cat("  outputs/tables/dimension_loadings.csv\n")
