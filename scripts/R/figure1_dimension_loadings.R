# FIGURE 3: Factor analysis loadings by dimension
# Shows how each variable contributes to its dimension

library(tidyverse)
library(ggh4x)
source("scripts/R/00_functions.R")

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

# Pad panels so every panel in the same row has equal bar count
dim_levels <- levels(loadings$dimension)
n_per_row <- ceiling(length(dim_levels) / 2)
vars_count <- loadings %>% count(dimension, .drop = FALSE) %>% arrange(dimension)

row_max <- c(
  max(vars_count$n[1:n_per_row]),
  max(vars_count$n[(n_per_row + 1):nrow(vars_count)])
)
row_heights <- row_max

padding <- map_dfr(seq_len(nrow(vars_count)), function(i) {
  row_idx <- if (i <= n_per_row) 1 else 2
  n_pad <- row_max[row_idx] - vars_count$n[i]
  if (n_pad > 0) {
    tibble(
      variable = paste0(".pad_", vars_count$dimension[i], "_", seq_len(n_pad)),
      loading = 0,
      label = paste0(".pad_", vars_count$dimension[i], "_", seq_len(n_pad)),
      dimension = vars_count$dimension[i]
    )
  }
})

loadings <- bind_rows(loadings, padding) %>%
  mutate(is_pad = startsWith(label, ".pad")) %>%
  arrange(dimension, desc(is_pad), loading) %>%
  mutate(label = factor(label, levels = unique(label))) %>%
  select(-is_pad)

# CREATE PLOT
cat("Creating loadings plot...\n")

p_loadings <- ggplot(loadings, aes(x = label, y = loading, fill = loading > 0)) +
  geom_col(show.legend = FALSE, width = 0.5) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~ dimension, scales = "free_y", nrow = 2) +
  force_panelsizes(rows = row_heights) +
  scale_fill_manual(values = c("TRUE" = "#c0392b", "FALSE" = "#2980b9")) +
  scale_x_discrete(labels = function(x) ifelse(startsWith(x, ".pad"), "", x)) +
  coord_flip() +
  labs(
    title = "Factor Analysis Loadings by Dimension",
    subtitle = "Contribution of each variable to the dimension score (1-factor FA)",
    x = NULL,
    y = "Loading"
  ) +
  theme_hockey() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    #strip.text = element_text(size = 12),
    axis.text.y = element_text(size = 9),
    axis.text.x = element_text(size = 9)
  )

# Save
ggsave("outputs/figures/figure1_dimension_loadings.png", p_loadings,
       width = 10, height = 6, dpi = 150)

cat("Saved: outputs/figures/figure1_dimension_loadings.png\n")
print(p_loadings)
