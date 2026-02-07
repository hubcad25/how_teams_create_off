# FIGURE 8: Goals/60 by cluster (LEAD VISUAL)
# Strip plot showing offensive production by cluster

library(tidyverse)
source("scripts/R/00_functions.R")
library(ggrepel)

# Read data
df_teams <- read_csv("data/processed/team_clustered.csv", show_col_types = FALSE) %>%
  mutate(cluster = factor(cluster))

df_metrics <- read_csv("data/processed/team_metrics_latest.csv", show_col_types = FALSE)

# Join data
df_output <- df_teams %>%
  left_join(df_metrics %>% select(team, output_goals_per60), by = "team")

league_avg <- mean(df_output$output_goals_per60)

# Order clusters by mean GF/60
cluster_means <- df_output %>%
  group_by(cluster) %>%
  summarise(
    mean_goals = mean(output_goals_per60),
    sd_goals = sd(output_goals_per60),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    ci_lo = mean_goals - 1.96 * sd_goals,
    ci_hi = mean_goals + 1.96 * sd_goals,
    cluster_rank = rank(-mean_goals)
  ) %>%
  arrange(cluster_rank)

cluster_order <- cluster_means$cluster
df_output <- df_output %>%
  mutate(cluster_ordered = factor(cluster, levels = rev(cluster_order)))

cluster_means <- cluster_means %>%
  mutate(cluster_ordered = factor(cluster, levels = rev(cluster_order)))

# Unique y position per team (manual dodge)
df_strip <- df_output %>%
  arrange(cluster_ordered, output_goals_per60) %>%
  group_by(cluster_ordered) %>%
  mutate(y_dodge = as.numeric(cluster_ordered) +
           seq(-0.38, 0.38, length.out = n())) %>%
  ungroup()

cluster_means <- cluster_means %>%
  mutate(y_pos = as.numeric(cluster_ordered))

# CREATE PLOT
cat("Creating goals/60 strip plot...\n")

p_strip <- ggplot(df_strip, aes(x = output_goals_per60, y = y_dodge, color = cluster)) +
  geom_vline(xintercept = league_avg, linetype = "dotted", color = "grey50", linewidth = 0.5) +
  geom_rect(data = cluster_means,
            aes(xmin = ci_lo, xmax = ci_hi,
                ymin = y_pos - 0.45, ymax = y_pos + 0.45,
                fill = cluster),
            alpha = 0.06, color = NA, inherit.aes = FALSE, show.legend = FALSE) +
  geom_point(data = cluster_means,
             aes(x = mean_goals, y = y_pos, color = cluster),
             size = 22, alpha = 0.12, show.legend = FALSE) +
  geom_point(size = 3, alpha = 0.85, show.legend = FALSE) +
  geom_text(aes(label = team), size = 2.8, nudge_y = 0.2, show.legend = FALSE) +
  scale_color_manual(values = cluster_colors[1:6]) +
  scale_fill_manual(values = cluster_colors[1:6]) +
  scale_y_continuous(
    breaks = seq_along(cluster_order),
    labels = cluster_names[rev(as.character(cluster_order))]
  ) +
  labs(
    title = "Goals/60 by Offensive Archetype",
    subtitle = "Dotted line = league avg | Circle = cluster mean | Band = 95% CI",
    x = "Goals/60 (5v5)",
    y = NULL
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.text.y = element_text(size = 11, face = "bold"),
    panel.grid.major.y = element_blank()
  )

# Save
ggsave("outputs/figures/figure6_goals_strip.png", p_strip,
       width = 11, height = 7, dpi = 150)

cat("Saved: outputs/figures/figure6_goals_strip.png\n")
print(p_strip)
