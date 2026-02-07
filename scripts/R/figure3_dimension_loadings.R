# FIGURE 3: Factor analysis loadings by dimension
# Shows how each variable contributes to its dimension

library(tidyverse)
library(clessnize)

# Read data
loadings <- read_csv("outputs/tables/dimension_loadings.csv", show_col_types = FALSE)
metric_labels <- readRDS("data/processed/metric_labels.rds")

# Create readable labels
loadings <- loadings %>%
  mutate(
    label = ifelse(variable %in% names(metric_labels),
                   metric_labels[variable],
                   gsub("^(input|output)_", "", variable)),
    # Rename dimensions to English
    dimension = case_when(
      dimension == "Misc_1" ~ "Recovery+Possession",
      dimension == "Misc_2" ~ "Puck exchanges",
      dimension == "Qualite" ~ "Quality",
      dimension == "Rebonds" ~ "Rebounds",
      dimension == "RecoveryPossession" ~ "Recovery+Possession",
      dimension == "PuckExchanges" ~ "Puck exchanges",
      TRUE ~ dimension
    ),
    dimension = factor(dimension,
                       levels = c("Volume", "Quality", "Penetration",
                                  "Rebounds", "Finishing", "Recovery+Possession",
                                  "Puck exchanges"))
  )

# CREATE PLOT
cat("Creating loadings plot...\n")

p_loadings <- ggplot(loadings, aes(x = reorder(label, loading), y = loading,
                                    fill = loading > 0)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~dimension, scales = "free_y", ncol = 2) +
  scale_fill_manual(values = c("TRUE" = "#c0392b", "FALSE" = "#2980b9")) +
  coord_flip() +
  labs(
    title = "Factor Analysis Loadings by Dimension",
    subtitle = "Contribution of each variable to the dimension score (1-factor FA)",
    x = NULL,
    y = "Loading"
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    strip.text = element_text(face = "bold", size = 12),
    axis.text.y = element_text(size = 9)
  )

# Save
ggsave("outputs/figures/figure3_dimension_loadings.png", p_loadings,
       width = 13, height = 12, dpi = 150)

cat("Saved: outputs/figures/figure3_dimension_loadings.png\n")
print(p_loadings)
