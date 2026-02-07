# Nettoyage des données historiques (2020-21 to 2024-25)
# Même pipeline que 02_clean_data.R

library(tidyverse)

# Fonction de nettoyage (copiée de 02_clean_data.R)
clean_season_data <- function(df_raw) {

  df_metrics <- df_raw %>%
    mutate(

      # INPUTS: VOLUME D'ATTAQUE (per 60 minutes)
      iceTime_minutes = iceTime / 60,

      input_shotAttempts_per60 = (shotAttemptsFor / iceTime) * 3600,
      input_unblockedShots_per60 = (unblockedShotAttemptsFor / iceTime) * 3600,
      input_shotsOnGoal_per60 = (shotsOnGoalFor / iceTime) * 3600,
      input_xGoals_per60 = (xGoalsFor / iceTime) * 3600,

      input_corsi_pct = corsiPercentage,
      input_fenwick_pct = fenwickPercentage,

      # INPUTS: QUALITÉ/SÉLECTION DE TIRS
      input_xG_per_shotAttempt = xGoalsFor / shotAttemptsFor,
      input_xG_per_unblockedShot = xGoalsFor / unblockedShotAttemptsFor,
      input_xG_per_SOG = xGoalsFor / shotsOnGoalFor,

      total_danger_shots = lowDangerShotsFor + mediumDangerShotsFor + highDangerShotsFor,

      input_pct_highDanger = highDangerShotsFor / total_danger_shots,
      input_pct_mediumDanger = mediumDangerShotsFor / total_danger_shots,
      input_pct_lowDanger = lowDangerShotsFor / total_danger_shots,

      input_ratio_HD_LD = highDangerShotsFor / lowDangerShotsFor,
      input_ratio_HD_MD = highDangerShotsFor / mediumDangerShotsFor,
      input_ratio_MD_LD = mediumDangerShotsFor / lowDangerShotsFor,

      # INPUTS: EFFICACITÉ/COMPLÉTION DES TIRS
      input_shot_completion_rate = shotsOnGoalFor / shotAttemptsFor,
      input_unblocked_rate = unblockedShotAttemptsFor / shotAttemptsFor,

      input_blocked_shot_rate = blockedShotAttemptsFor / shotAttemptsFor,
      input_missed_net_rate = missedShotsFor / unblockedShotAttemptsFor,

      # INPUTS: CRÉATION DE CHANCES
      input_rebounds_per60 = (reboundsFor / iceTime) * 3600,
      input_takeaways_per60 = (takeawaysFor / iceTime) * 3600,
      input_giveaways_per60 = (giveawaysFor / iceTime) * 3600,

      input_takeaway_giveaway_ratio = takeawaysFor / giveawaysFor,

      input_xG_per_rebound = reboundxGoalsFor / reboundsFor,
      input_pct_xG_from_rebounds = reboundxGoalsFor / xGoalsFor,

      # INPUTS: DISCIPLINE
      input_penalty_differential_per60 = ((penaltiesAgainst - penaltiesFor) / iceTime) * 3600,
      input_penalties_taken_per60 = (penaltiesFor / iceTime) * 3600,

      # INPUTS: OPTIONNELS (style de jeu)
      input_faceoff_win_pct = faceOffsWonFor / (faceOffsWonFor + faceOffsWonAgainst),
      input_hits_per60 = (hitsFor / iceTime) * 3600,
      input_zone_exit_success = playContinuedOutsideZoneFor /
                                (playContinuedOutsideZoneFor + playContinuedInZoneFor),

      # OUTPUTS: RÉSULTATS/SUCCÈS OFFENSIF (conversion)
      output_goals_per60 = (goalsFor / iceTime) * 3600,
      output_goals_pct = goalsFor / (goalsFor + goalsAgainst),

      output_xGoals_pct = xGoalsFor / (xGoalsFor + xGoalsAgainst),

      output_ratio_GF_xG = (goalsFor / (goalsFor + goalsAgainst)) /
                           (xGoalsFor / (xGoalsFor + xGoalsAgainst)),

      output_shooting_pct_SOG = goalsFor / shotsOnGoalFor,
      output_shooting_pct_unblocked = goalsFor / unblockedShotAttemptsFor,
      output_shooting_pct_attempts = goalsFor / shotAttemptsFor,

      output_shooting_pct_vs_expected = (goalsFor / shotsOnGoalFor) -
                                         (xGoalsFor / shotsOnGoalFor),
      output_goals_above_expected = goalsFor - xGoalsFor,

      output_pct_goals_highDanger = highDangerGoalsFor / goalsFor,
      output_pct_goals_mediumDanger = mediumDangerGoalsFor / goalsFor,
      output_pct_goals_lowDanger = lowDangerGoalsFor / goalsFor,

      output_reboundGoals_per60 = (reboundGoalsFor / iceTime) * 3600,
      output_rebound_conversion = reboundGoalsFor / reboundsFor,

      output_shooting_pct_HD = highDangerGoalsFor / highDangerShotsFor,
      output_shooting_pct_MD = mediumDangerGoalsFor / mediumDangerShotsFor,
      output_shooting_pct_LD = lowDangerGoalsFor / lowDangerShotsFor,

      output_HD_goals_vs_xG = highDangerGoalsFor / highDangerxGoalsFor,
      output_MD_goals_vs_xG = mediumDangerGoalsFor / mediumDangerxGoalsFor,
      output_LD_goals_vs_xG = lowDangerGoalsFor / lowDangerxGoalsFor
    )

  # Sélection des variables finales
  df_clean <- df_metrics %>%
    select(
      team, name, season_year, games_played, iceTime_minutes,
      starts_with("input_"),
      starts_with("output_")
    )

  return(df_clean)
}

# Liste des saisons historiques
seasons <- c("2020", "2021", "2022", "2023", "2024")

cat("Nettoyage des données historiques...\n")
cat("===================================\n\n")

all_clean <- list()

for (season in seasons) {
  cat(paste0("Saison ", season, "-", as.integer(season)+1, ":\n"))

  # Chargement
  input_file <- paste0("data/historical/team_data_", season, ".csv")
  df_raw <- read_csv(input_file, show_col_types = FALSE)

  cat("  ", nrow(df_raw), "équipes\n")

  # Nettoyage
  df_clean <- clean_season_data(df_raw)

  # Vérification
  n_issues <- df_clean %>%
    select(where(is.numeric)) %>%
    summarise(across(everything(), ~ sum(is.na(.) | is.infinite(.), na.rm = TRUE))) %>%
    sum()
  cat("  ", ncol(df_clean), "colonnes,", n_issues, "NaN/Inf\n")

  # Sauvegarde
  output_file <- paste0("data/cleaned/team_data_clean_", season, ".csv")
  write_csv(df_clean, output_file)
  cat("  Sauvegardé:", output_file, "\n\n")

  all_clean[[season]] <- df_clean
}

# Combiner toutes les saisons
df_all_seasons <- bind_rows(all_clean)

cat("===================================\n")
cat("TOTAL:", nrow(df_all_seasons), "équipes-saisons\n")
cat("Colonnes:", ncol(df_all_seasons), "\n\n")

# Sauvegarder le fichier combiné
write_csv(df_all_seasons, "data/cleaned/all_seasons_clean.csv")
cat("Fichier combiné: data/cleaned/all_seasons_clean.csv\n\n")

# Vérifier que les colonnes correspondent à 2025-26
df_current <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

current_cols <- colnames(df_current)
hist_cols <- colnames(df_all_seasons)

common_cols <- intersect(current_cols, hist_cols)

cat("Comparaison avec 2025-26:\n")
cat("  Colonnes 2025-26:", length(current_cols), "\n")
cat("  Colonnes historiques:", length(hist_cols), "\n")
cat("  Colonnes communes:", length(common_cols), "\n")

if (setequal(current_cols, hist_cols)) {
  cat("\n✓ Structures identiques!\n")
} else {
  cat("\n⚠ Colonnes différentes:\n")
  cat("  Seulement dans 2025-26:", setdiff(current_cols, hist_cols), "\n")
  cat("  Seulement dans historique:", setdiff(hist_cols, current_cols), "\n")
}

cat("\nScript terminé.\n")
