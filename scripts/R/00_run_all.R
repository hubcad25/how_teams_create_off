# Master script: Run all analyses and generate all figures
# Execute this script to reproduce the entire analysis pipeline

library(tidyverse)

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  NHL OFFENSIVE STYLES ANALYSIS - FULL PIPELINE                 ║\n")
cat("║  2025-26 Season + Historical (2020-21 to 2024-25)              ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Create output directories
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("data/historical", showWarnings = FALSE, recursive = TRUE)
dir.create("data/cleaned", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

# Timer
start_time <- Sys.time()
script_dir <- here::here("scripts/R")

# Helper function to run script
run_script <- function(script_name, description) {
  cat(sprintf("\n▶ %s\n", description))
  cat(strrep("─", 70), "\n")

  script_path <- file.path(script_dir, script_name)

  tryCatch({
    source(script_path, local = TRUE, echo = FALSE)
    cat(sprintf("✓ %s complete\n", script_name))
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("✗ ERROR in %s:\n", script_name))
    cat(e$message, "\n")
    return(FALSE)
  })
}

# ═══════════════════════════════════════════════════════════════════════
# PART 1: DATA CLEANING
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 1: DATA CLEANING                                         ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success <- list()

success$clean_2025 <- run_script(
  "01_clean_data_2025_26.R",
  "1. Clean 2025-26 MoneyPuck data"
)

success$clean_hist <- run_script(
  "02_clean_data_historical.R",
  "2. Clean historical data (2020-21 to 2024-25)"
)

# ═══════════════════════════════════════════════════════════════════════
# PART 2: DIMENSION ANALYSIS
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 2: DIMENSION ANALYSIS (FA)                               ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success$fa <- run_script(
  "03_analysis_dimension_scores.R",
  "3. Factor Analysis: 7 orthogonal dimensions"
)

success$hclust <- run_script(
  "03b_analysis_hierarchical_clustering.R",
  "4. Hierarchical clustering (Ward D2)"
)

# ═══════════════════════════════════════════════════════════════════════
# PART 3: CLUSTERING
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 3: CLUSTER ASSIGNMENT                                     ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success$cluster <- run_script(
  "04_analysis_cluster_assignments.R",
  "5. Assign teams to k=6 clusters"
)

success$apply_hist <- run_script(
  "05_analysis_apply_clusters_historical.R",
  "6. Apply 2025-26 model to historical seasons"
)

# ═══════════════════════════════════════════════════════════════════════
# PART 4: FIGURES - DIMENSIONS
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 4: FIGURES - DIMENSIONS                                  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success$fig1 <- run_script(
  "figure1_dimensions_heatmap.R",
  "Figure 1: Team offensive profiles (heatmap)"
)

success$fig2 <- run_script(
  "figure2_dimensions_parallel.R",
  "Figure 2: Parallel coordinates plot"
)

success$fig3 <- run_script(
  "figure3_dimension_loadings.R",
  "Figure 3: FA loadings by dimension"
)

# ═══════════════════════════════════════════════════════════════════════
# PART 5: FIGURES - CLUSTERING
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 5: FIGURES - CLUSTERING                                   ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success$fig4 <- run_script(
  "figure4_dendrogram_k_selection.R",
  "Figure 4: Dendrogram k-selection (k=3-7)"
)

success$fig5 <- run_script(
  "figure5_dendrogram_heatmap_k6.R",
  "Figure 5: Dendrogram + heatmap (k=6)"
)

# ═══════════════════════════════════════════════════════════════════════
# PART 6: FIGURES - CLUSTER PROFILES
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 6: FIGURES - CLUSTER PROFILES                             ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success$fig6 <- run_script(
  "figure6_cluster_profiles_bars.R",
  "Figure 6: Cluster profiles (bar chart)"
)

success$fig7 <- run_script(
  "figure7_teams_by_cluster_profile.R",
  "Figure 7: Team profiles by cluster"
)

# ═══════════════════════════════════════════════════════════════════════
# PART 7: FIGURES - PERFORMANCE ANALYSIS
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 7: FIGURES - PERFORMANCE ANALYSIS                         ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success$fig8 <- run_script(
  "figure8_goals_by_cluster_strip.R",
  "Figure 8: Goals/60 by cluster (LEAD VISUAL) ★"
)

success$fig9 <- run_script(
  "figure9_regression_effects.R",
  "Figure 9: Bootstrap regression effects"
)

success$fig10 <- run_script(
  "figure10_finishing_vs_goals.R",
  "Figure 10: Finishing vs Goals/60"
)

# Appendix
success$app1 <- run_script(
  "appendix_goals_vs_xg_scatter.R",
  "Appendix: Goals vs xG scatter"
)

# ═══════════════════════════════════════════════════════════════════════
# PART 8: FIGURES - HISTORICAL ANALYSIS
# ═══════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PART 8: FIGURES - HISTORICAL EVOLUTION                         ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n")

success$fig11 <- run_script(
  "figure11_cluster_evolution.R",
  "Figure 11: Cluster evolution 2020-2026"
)

success$fig12 <- run_script(
  "figure12_team_trajectories.R",
  "Figure 12: Team trajectories heatmap"
)

# ═══════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════

end_time <- Sys.time()
duration <- difftime(end_time, start_time, units = "mins")

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PIPELINE COMPLETE                                               ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

n_success <- sum(unlist(success))
n_total <- length(success)

cat(sprintf("Scripts executed: %d/%d successful\n", n_success, n_total))
cat(sprintf("Total time: %.1f minutes\n\n", as.numeric(duration)))

if (n_success < n_total) {
  cat("⚠ Failed scripts:\n")
  for (name in names(success)) {
    if (!success[[name]]) {
      cat(sprintf("  - %s\n", name))
    }
  }
  cat("\n")
}

# List generated figures
figures <- list.files("outputs/figures", pattern = "\\.png$", full.names = FALSE)
figures <- sort(figures)

cat("Generated figures:\n")
for (fig in figures) {
  fig_path <- file.path("outputs/figures", fig)
  fig_size <- file.info(fig_path)$size / 1024  # KB
  cat(sprintf("  ✓ %s (%.0f KB)\n", fig, fig_size))
}

cat("\n")
cat("─────────────────────────────────────────────────────────────────\n")
cat("All outputs saved to:\n")
cat("  - Data: data/processed/, data/historical/\n")
cat("  - Tables: outputs/tables/\n")
cat("  - Figures: outputs/figures/\n")
cat("─────────────────────────────────────────────────────────────────\n")
