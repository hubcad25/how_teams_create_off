# FIGURE 8: Bootstrap regression effects by cluster
# Lollipop plot: coefficient + 90%/95% CI, faceted by dimension

library(tidyverse)
source("scripts/R/00_functions.R")
library(MASS)

cat("Bootstrap regression: dimension effects on GF/60\n\n")

# Read data
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE) %>%
  mutate(cluster = factor(cluster))
df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

score_cols <- c("Volume", "Qualite", "Penetration", "Rebonds",
                "Finishing", "RecoveryPossession", "PuckExchanges")

dimension_labels <- c(
  "Volume"             = "Volume",
  "Qualite"            = "Quality",
  "Penetration"        = "Penetration",
  "Rebonds"            = "Rebounds",
  "RecoveryPossession" = "Recovery+Poss.",
  "PuckExchanges"      = "Puck Exchanges",
  "Finishing"          = "Finishing"
)

# Join data
df_output <- df_teams %>%
  left_join(df_metrics %>% dplyr::select(team, output_goals_per60), by = "team")

# GENERATE SIMULATED DATA (bootstrap)
set.seed(42)
N_SIM <- 100
sim_vars <- c(score_cols, "output_goals_per60")

shrink_cov <- function(x, lambda = 0.3) {
  S <- cov(x)
  D <- diag(diag(S))
  (1 - lambda) * S + lambda * D
}

df_sim <- map_dfr(levels(df_output$cluster), function(cl) {
  sub <- df_output %>% filter(cluster == cl) %>% dplyr::select(all_of(sim_vars))
  n_obs <- nrow(sub)
  mu <- colMeans(sub)
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

# Extract cluster-specific effects with CIs using vcov
V <- vcov(mod_sim)
base_coefs <- coef(mod_sim)
ref_cluster <- levels(df_sim$cluster)[1]

sim_effects <- map_dfr(levels(df_sim$cluster), function(cl) {
  map_dfr(score_cols, function(dim) {
    base <- base_coefs[dim]
    interact_name <- paste0("cluster", cl, ":", dim)

    if (cl == ref_cluster) {
      effect <- base
      se <- sqrt(V[dim, dim])
    } else {
      interact <- ifelse(interact_name %in% names(base_coefs),
                         base_coefs[interact_name], 0)
      effect <- base + interact
      if (interact_name %in% rownames(V)) {
        se <- sqrt(V[dim, dim] + V[interact_name, interact_name] +
                     2 * V[dim, interact_name])
      } else {
        se <- sqrt(V[dim, dim])
      }
    }

    tibble(cluster = cl, dimension = dim,
           effect = effect, se = se)
  })
})

# Add base (no interaction) row
main_coefs <- coef(mod_main)
V_main <- vcov(mod_main)

base_effects <- tibble(
  cluster = "base",
  dimension = score_cols,
  effect = main_coefs[score_cols],
  se = map_dbl(score_cols, ~ sqrt(V_main[.x, .x]))
)

sim_effects <- bind_rows(base_effects, sim_effects)

# Compute CIs and p-values
sim_effects <- sim_effects %>%
  mutate(
    ci90_lo = effect - 1.645 * se,
    ci90_hi = effect + 1.645 * se,
    ci95_lo = effect - 1.96 * se,
    ci95_hi = effect + 1.96 * se,
    pval = 2 * pnorm(-abs(effect / se)),
    sig = case_when(
      pval <= 0.05 ~ "p < 0.05",
      pval <= 0.10 ~ "p < 0.10",
      TRUE          ~ "n.s."
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "n.s."))
  )

# Order clusters by mean GF/60 (base on top)
cluster_gf_order <- df_output %>%
  group_by(cluster) %>%
  summarise(mean_gf = mean(output_goals_per60), .groups = "drop") %>%
  arrange(mean_gf) %>%
  pull(cluster) %>%
  as.character()

cluster_y_levels <- c(cluster_gf_order, "base")
cluster_y_labels <- setNames(
  c(cluster_names[cluster_gf_order], "Base (all archetypes)"),
  cluster_y_levels
)

colors_with_base <- c(cluster_colors, "base" = "black")

sim_effects <- sim_effects %>%
  mutate(
    cluster = factor(cluster, levels = cluster_y_levels),
    dimension = factor(dimension_labels[dimension], levels = dimension_labels)
  )

# CREATE PLOT
cat("Creating effects lollipop...\n")

p <- ggplot(sim_effects, aes(x = effect, y = cluster, color = cluster, alpha = sig)) +
  geom_vline(xintercept = 0, linetype = "dotted", color = "grey50", linewidth = 0.65) +
  geom_linerange(aes(x = effect, y = cluster, xmin = ci95_lo, xmax = ci95_hi),
                 inherit.aes = FALSE, color = "white", linewidth = 1.2) +
  geom_linerange(aes(x = effect, y = cluster, xmin = ci90_lo, xmax = ci90_hi),
                 inherit.aes = FALSE, color = "white", linewidth = 2.2) +
  geom_linerange(aes(xmin = ci95_lo, xmax = ci95_hi), linewidth = 0.6) +
  geom_linerange(aes(xmin = ci90_lo, xmax = ci90_hi), linewidth = 1.5) +
  geom_point(aes(x = effect, y = cluster), inherit.aes = FALSE,
             color = "white", size = 2.2, shape = 16, show.legend = FALSE) +
  geom_point(size = 2.5, shape = 16, stroke = 0, show.legend = FALSE) +
  geom_label(aes(x = effect, y = cluster, color = cluster,
                 label = ifelse(effect >= 0,
                                sprintf("+%.2f", effect),
                                sprintf("%.2f", effect))),
             inherit.aes = FALSE,
             size = 2.5, nudge_y = 0.2,
             fill = "white", label.size = 0, label.padding = unit(0.15, "lines"),
             show.legend = FALSE) +
  scale_color_manual(values = colors_with_base) +
  scale_alpha_manual(values = c("p < 0.05" = 1, "p < 0.10" = 0.4, "n.s." = 0.2)) +
  facet_wrap(~ dimension, nrow = 1) +
  scale_y_discrete(labels = cluster_y_labels) +
  scale_x_continuous(
#    breaks = c(-0.25, 0, 0.25)
  ) +
  coord_cartesian(
    xlim = c(-0.775, 0.775)
  ) +
  labs(
    title = "Dimension Effects on Goals/60 by Archetype",
    subtitle = "Thick segment = 90% CI | Thin segment = 95% CI",
    x = "\nCoefficient",
    y = NULL,
    caption = str_wrap(paste0(
      "Method: ", N_SIM, " synthetic observations per cluster generated from a multivariate normal ",
      "(cluster mean + shrinkage-regularized covariance). OLS with cluster interactions. ",
      "CI width depends on simulated sample size: coefficients reflect within-cluster correlations, ",
      "not causal effects. Clusters with less than 5 observations use stronger shrinkage toward diagonal covariance."), 120),
    alpha = NULL
  ) +
  guides(color = "none") +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    strip.text = element_text(size = 9),
    axis.text.y = element_text(size = 9),
    axis.text.x = element_text(size = 7),
    legend.position = "bottom",
    panel.spacing = unit(0.5, "lines"),
    panel.border = element_rect(color = "grey50")
  )

# Save
ggsave("outputs/figures/figure8_regression_effects.png", p,
       width = 9.5, height = 5.5, dpi = 300)

write_csv(sim_effects, "outputs/tables/sim_regression_effects.csv")

cat("Saved: outputs/figures/figure8_regression_effects.png\n")
cat("Saved: outputs/tables/sim_regression_effects.csv\n")
print(p)
