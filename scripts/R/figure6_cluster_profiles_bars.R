# FIGURE 6: Cluster profiles bar chart
# Shows mean dimension scores for each cluster

library(tidyverse)
library(clessnize)

# Read data
profiles <- read_csv("outputs/tables/cluster_profiles.csv", show_col_types = FALSE)

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

# Prepare data
profiles_long <- profiles %>%
  pivot_longer(cols = all_of(score_cols), names_to = "Dimension", values_to = "Score") %>%
  mutate(
    Dimension = case_when(
      Dimension == "Qualite" ~ "Quality",
      Dimension == "Rebonds" ~ "Rebounds",
      Dimension == "RecoveryPossession" ~ "Recovery+Possession",
      Dimension == "PuckExchanges" ~ "Puck exchanges",
      TRUE ~ Dimension
    ),
    Dimension = factor(Dimension, levels = c("Volume", "Quality", "Penetration",
                                             "Rebounds", "Finishing",
                                             "Recovery+Possession", "Puck exchanges"))
  )

# Cluster colors
cluster_colors <- c("#e74c3c", "#3498db", "#27ae60", "#9b59b6",
                    "#f39c12", "#1abc9c")

# CREATE PLOT
cat("Creating cluster profiles bar chart...\n")

p_bars <- ggplot(profiles_long, aes(x = Dimension, y = Score, fill = Score > 0)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~cluster, ncol = 3,
             labeller = labeller(cluster = cluster_names_map)) +
  scale_fill_manual(values = c("TRUE" = "#27ae60", "FALSE" = "#e74c3c")) +
  coord_cartesian(ylim = c(-3, 3)) +
  labs(
    title = "Cluster Profiles: Mean Dimension Scores",
    subtitle = "k=6 hierarchical clustering (Ward) on 7 FA dimensions",
    x = NULL,
    y = "Score (z)"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    strip.text = element_text(face = "bold", size = 11),
    axis.text.x = element_text(angle = 90, hjust = 0.5, vjust = 0.5, size = 9),
    panel.border = element_rect(color = "grey85", fill = NA, linewidth = 0.5)
  )

# Save
ggsave("outputs/figures/figure6_cluster_profiles_bars.png", p_bars,
       width = 12, height = 8, dpi = 150)

cat("Saved: outputs/figures/figure6_cluster_profiles_bars.png\n")
print(p_bars)
