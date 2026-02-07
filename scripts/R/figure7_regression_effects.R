# FIGURE 9: Bootstrap regression effects by cluster
# Shows which dimensions drive GF/60 within each cluster

library(tidyverse)
library(clessnize)
library(MASS)

cat("Bootstrap regression: dimension effects on GF/60\n\n")

# Read data
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE) %>%
  mutate(cluster = factor(cluster))
df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

# Cluster names
cluster_names_map <- c(
  "1" = "Crash & Hope",
  "2" = "High-Octane Drive",
  "3" = "Streaky Offense",
  "4" = "Selective Shooting",
  "5" = "Lane Creation",
  "6" = "Puck Hog & Finish"
)

score_cols <- c("Volume", "Qualite", "Penetration", "Rebonds",
                "Finishing", "RecoveryPossession", "PuckExchanges")

# Join data
df_output <- df_teams %>%
  left_join(df_metrics %>% dplyr::select(team, output_goals_per60, input_xGoals_per60), by = "team")

# GENERATE SIMULATED DATA (bootstrap)
set.seed(42)
N_SIM <- 500  # simulated observations per cluster
sim_vars <- c(score_cols, "output_goals_per60")

# Regularized covariance (shrinkage towards diagonal)
shrink_cov <- function(x, lambda = 0.3) {
  S <- cov(x)
  D <- diag(diag(S))
  (1 - lambda) * S + lambda * D
}

# Generate synthetic observations per cluster
df_sim <- map_dfr(levels(df_output$cluster), function(cl) {
  sub <- df_output %>% filter(cluster == cl) %>% dplyr::select(all_of(sim_vars))
  n_obs <- nrow(sub)
  mu <- colMeans(sub)

  # More shrinkage for small clusters
  lam <- case_when(n_obs <= 3 ~ 0.7, n_obs <= 5 ~ 0.5, TRUE ~ 0.3)
  Sigma <- shrink_cov(sub, lambda = lam)

  synth <- mvrnorm(n = N_SIM, mu = mu, Sigma = Sigma)
  as_tibble(synth) %>% mutate(cluster = cl)
})

df_sim <- df_sim %>% mutate(cluster = factor(cluster))

cat(sprintf("  %d simulated observations (%d per cluster)\n\n",
            nrow(df_sim), N_SIM))

# REGRESSION WITH INTERACTIONS
formula_interact <- as.formula(
  paste("output_goals_per60 ~ cluster * (",
        paste(score_cols, collapse = " + "), ")")
)

mod_sim <- lm(formula_interact, data = df_sim)
cat(sprintf("  R² = %.3f, R² adj = %.3f\n\n",
            summary(mod_sim)$r.squared, summary(mod_sim)$adj.r.squared))

# Model WITHOUT interaction for base coefficients
formula_main <- as.formula(
  paste("output_goals_per60 ~ cluster +",
        paste(score_cols, collapse = " + "))
)

mod_main <- lm(formula_main, data = df_sim)
main_coefs <- coef(mod_main)

# Extract effects by cluster (main effect + interaction)
base_coefs <- coef(mod_sim)
ref_cluster <- levels(df_sim$cluster)[1]

sim_effects <- map_dfr(levels(df_sim$cluster), function(cl) {
  map_dfr(score_cols, function(dim) {
    # Base effect (reference cluster)
    base <- base_coefs[dim]
    # Interaction for this cluster
    interact_name <- paste0("cluster", cl, ":", dim)
    interact <- ifelse(cl == ref_cluster, 0,
                       ifelse(interact_name %in% names(base_coefs),
                              base_coefs[interact_name], 0))
    tibble(cluster = cl, dimension = dim, effect = base + interact)
  })
}) %>%
  mutate(
    cluster = factor(cluster, levels = c("2", "6", "4", "3", "1", "5")),
    dimension = factor(dimension, levels = score_cols)
  )

# Add base coefficients (no interaction)
base_effects <- tibble(
  cluster = "Base (no interaction)",
  dimension = score_cols,
  effect = main_coefs[score_cols]
) %>%
  mutate(
    cluster = factor(cluster, levels = c("Base (no interaction)", levels(sim_effects$cluster))),
    dimension = factor(dimension, levels = score_cols)
  )

sim_effects <- bind_rows(base_effects, sim_effects)

# Create custom labels
sim_effects <- sim_effects %>%
  mutate(
    cluster_label = ifelse(cluster == "Base (no interaction)",
                          "Base (no interaction)",
                          cluster_names_map[as.character(cluster)])
  )

# Order clusters
cluster_order_sim <- c("Base (no interaction)",
                       "2", "6", "4", "3", "1", "5")
cluster_labels_sim <- c("Base (no interaction)",
                       "High-Octane Drive", "Puck Hog & Finish", "Selective Shooting",
                       "Streaky Offense", "Crash & Hope", "Lane Creation")

# CREATE HEATMAP
cat("Creating effects heatmap...\n")

p_sim_effects <- ggplot(sim_effects,
                        aes(x = dimension, y = cluster, fill = effect)) +
  geom_tile(color = "white", linewidth = 0.5) +
  # Add distinctive border for "Base" row
  geom_tile(data = sim_effects %>% filter(cluster == "Base (no interaction)"),
            aes(x = dimension, y = cluster),
            fill = NA, color = "#2c3e50", linewidth = 2.5, inherit.aes = FALSE) +
  geom_text(aes(label = sprintf("%.2f", effect)), size = 4, fontface = "bold") +
  scale_fill_gradient2(
    low = "#2980b9", mid = "white", high = "#c0392b",
    midpoint = 0
  ) +
  scale_y_discrete(labels = cluster_labels_sim) +
  labs(
    title = "Dimension Effects on Goals/60 by Cluster",
    subtitle = sprintf("Top row: main effects | Other rows: cluster-specific effects | %d simulated obs",
                       nrow(df_sim)),
    x = NULL,
    y = "Cluster",
    fill = "Coefficient"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.text.x = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 12)
  )

# Save
ggsave("outputs/figures/figure7_regression_effects.png", p_sim_effects,
       width = 11, height = 6, dpi = 150)

write_csv(sim_effects, "outputs/tables/sim_regression_effects.csv")

cat("Saved: outputs/figures/figure7_regression_effects.png\n")
cat("Saved: outputs/tables/sim_regression_effects.csv\n")
print(p_sim_effects)
