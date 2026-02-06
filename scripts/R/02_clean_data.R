# Nettoyage et calcul des métriques
# Saison 2025-26, statistiques 5v5

library(tidyverse)

# 1. CHARGEMENT DES DONNÉES ----

cat("Chargement des données...\n")

df_raw <- read_csv("data/raw/moneypuck_5v5_latest.csv",
                   show_col_types = FALSE)

cat(" ", nrow(df_raw), "équipes,", ncol(df_raw), "colonnes brutes\n\n")

# 2. CALCUL DES MÉTRIQUES DÉRIVÉES ----

cat("Calcul des métriques dérivées...\n")

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

cat("  Métriques calculées\n\n")

# 3. SÉLECTION DES VARIABLES FINALES ----

cat("Création de la dataframe finale...\n")

df_clean <- df_metrics %>%
  select(
    team, name, season, games_played, iceTime_minutes,
    starts_with("input_"),
    starts_with("output_")
  )

cat("  Identifiants:", ncol(df_clean %>% select(team:iceTime_minutes)), "colonnes\n")
cat("  Variables INPUT:", ncol(df_clean %>% select(starts_with("input_"))), "colonnes\n")
cat("  Variables OUTPUT:", ncol(df_clean %>% select(starts_with("output_"))), "colonnes\n")
cat("  TOTAL:", ncol(df_clean), "colonnes\n\n")

# 4. VÉRIFICATION DES DONNÉES ----

cat("Vérification des données...\n")

check_issues <- df_clean %>%
  select(starts_with("input_"), starts_with("output_")) %>%
  summarise(across(everything(),
                   ~sum(is.na(.) | is.infinite(.))))

n_issues <- sum(check_issues > 0)

if (n_issues > 0) {
  cat("  Problèmes détectés:\n")
  issues <- check_issues %>%
    pivot_longer(everything(), names_to = "variable", values_to = "n_issues") %>%
    filter(n_issues > 0) %>%
    arrange(desc(n_issues))
  print(issues)
  cat("\n")
} else {
  cat("  Aucun NaN ou Inf détecté\n\n")
}

# Aperçu
cat("Aperçu des données:\n")
print(df_clean %>% select(team, input_xGoals_per60, input_ratio_HD_LD,
                          output_goals_pct, output_ratio_GF_xG) %>%
      arrange(desc(output_goals_pct)) %>%
      head(10))

cat("\n")

# 5. SAUVEGARDE ----

cat("Sauvegarde des données...\n")

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
filename <- paste0("data/processed/team_metrics_", timestamp, ".csv")
filename_latest <- "data/processed/team_metrics_latest.csv"

write_csv(df_clean, filename)
write_csv(df_clean, filename_latest)

cat("  -", filename, "\n")
cat("  -", filename_latest, "\n\n")

# 6. STATISTIQUES DESCRIPTIVES ----

cat("Statistiques descriptives des INPUTS:\n")

summary_inputs <- df_clean %>%
  select(starts_with("input_")) %>%
  summary()

print(summary_inputs)

cat("\nStatistiques descriptives des OUTPUTS:\n")

summary_outputs <- df_clean %>%
  select(starts_with("output_")) %>%
  summary()

print(summary_outputs)

# 7. LABELS POUR GRAPHIQUES ----

metric_labels <- c(
  # INPUTS: Volume
  "input_shotAttempts_per60" = "Corsi/60",
  "input_unblockedShots_per60" = "Fenwick/60",
  "input_shotsOnGoal_per60" = "SOG/60",
  "input_xGoals_per60" = "xG/60",
  "input_corsi_pct" = "Corsi%",
  "input_fenwick_pct" = "Fenwick%",

  # INPUTS: Shot quality
  "input_xG_per_shotAttempt" = "xG/Corsi",
  "input_xG_per_unblockedShot" = "xG/Fenwick",
  "input_xG_per_SOG" = "xG/SOG",
  "input_pct_highDanger" = "HD shot %",
  "input_pct_mediumDanger" = "MD shot %",
  "input_pct_lowDanger" = "LD shot %",
  "input_ratio_HD_LD" = "HD/LD ratio",
  "input_ratio_HD_MD" = "HD/MD ratio",
  "input_ratio_MD_LD" = "MD/LD ratio",

  # INPUTS: Shot completion
  "input_shot_completion_rate" = "SOG/Corsi",
  "input_unblocked_rate" = "Fenwick/Corsi",
  "input_blocked_shot_rate" = "Blocked %",
  "input_missed_net_rate" = "Missed %",

  # INPUTS: Chance creation
  "input_rebounds_per60" = "Rebounds/60",
  "input_takeaways_per60" = "Takeaways/60",
  "input_giveaways_per60" = "Giveaways/60",
  "input_takeaway_giveaway_ratio" = "TK/GV ratio",
  "input_xG_per_rebound" = "xG/rebound",
  "input_pct_xG_from_rebounds" = "Rebound xG %",

  # INPUTS: Discipline
  "input_penalty_differential_per60" = "Penalty diff/60",
  "input_penalties_taken_per60" = "Penalties/60",

  # INPUTS: Optional
  "input_faceoff_win_pct" = "Faceoff %",
  "input_hits_per60" = "Hits/60",
  "input_zone_exit_success" = "Zone exit %",

  # OUTPUTS: Goals
  "output_goals_per60" = "Goals/60",
  "output_goals_pct" = "GF%",
  "output_xGoals_pct" = "xGF%",
  "output_ratio_GF_xG" = "GF%/xGF%",

  # OUTPUTS: Shooting
  "output_shooting_pct_SOG" = "Sh%",
  "output_shooting_pct_unblocked" = "Sh% (Fenwick)",
  "output_shooting_pct_attempts" = "Sh% (Corsi)",
  "output_shooting_pct_vs_expected" = "Sh% vs xSh%",
  "output_goals_above_expected" = "Goals - xG",

  # OUTPUTS: Goal distribution
  "output_pct_goals_highDanger" = "HD goal %",
  "output_pct_goals_mediumDanger" = "MD goal %",
  "output_pct_goals_lowDanger" = "LD goal %",

  # OUTPUTS: Rebound conversion
  "output_reboundGoals_per60" = "Rebound goals/60",
  "output_rebound_conversion" = "Rebound conv %",

  # OUTPUTS: Conversion by danger
  "output_shooting_pct_HD" = "HD Sh%",
  "output_shooting_pct_MD" = "MD Sh%",
  "output_shooting_pct_LD" = "LD Sh%",

  # OUTPUTS: Goals vs xG by danger
  "output_HD_goals_vs_xG" = "HD G/xG",
  "output_MD_goals_vs_xG" = "MD G/xG",
  "output_LD_goals_vs_xG" = "LD G/xG"
)

get_label <- function(var_name) {
  label <- metric_labels[var_name]
  if (is.na(label)) return(var_name)
  return(label)
}

saveRDS(metric_labels, "data/processed/metric_labels.rds")
cat("\nLabels sauvegardés: data/processed/metric_labels.rds\n")

cat("\nScript terminé.\n")
