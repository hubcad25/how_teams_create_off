# FIGURE 3: K-selection metrics (merge height, WSS, silhouette)
# Shows 3 metrics by k to justify choice of k=6

library(tidyverse)
library(cluster)
source("scripts/R/00_functions.R")

cat("Creating k-selection plot...\n")

# Load data
df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)
hc <- readRDS("data/processed/hclust_ward.rds")

score_cols <- setdiff(names(df_dim), c("team", "name"))
scores <- df_dim %>% select(all_of(score_cols)) %>% as.matrix()
rownames(scores) <- df_dim$team
d <- dist(scores)

k_range <- 2:8

# 1. Merge height: height of the last merge to go from k+1 to k clusters
#    = hc$height in reverse order (last merges are most costly)
n <- nrow(scores)
merge_heights <- tibble(
  k = 2:(n),
  height = rev(hc$height)
) %>%
  filter(k %in% k_range)

# 2. Within-cluster sum of squares
wss <- map_dbl(k_range, function(k) {
  clusters <- cutree(hc, k = k)
  sum(map_dbl(unique(clusters), function(cl) {
    members <- scores[clusters == cl, , drop = FALSE]
    sum(scale(members, scale = FALSE)^2)
  }))
})

# 3. Silhouette
sil <- map_dbl(k_range, function(k) {
  clusters <- cutree(hc, k = k)
  mean(silhouette(clusters, d)[, 3])
})

# Combine into long format
metrics <- bind_rows(
  tibble(k = k_range, value = merge_heights$height, metric = "Merge height"),
  tibble(k = k_range, value = wss, metric = "Within-cluster SS"),
  tibble(k = k_range, value = sil, metric = "Silhouette")
) %>%
  mutate(metric = factor(metric, levels = c("Merge height", "Within-cluster SS", "Silhouette")))

# Plot
p <- ggplot(metrics, aes(x = k, y = value)) +
  geom_line(linewidth = 0.8, color = "grey30") +
  geom_point(size = 2.5, color = "grey30") +
  geom_point(data = metrics %>% filter(k == 6),
             size = 4, color = "#c0392b") +
  geom_text(data = metrics %>% filter(k == 6),
            aes(label = sprintf("k=6")),
            hjust = -0.3, vjust = -0.5, size = 3.5, color = "#c0392b", fontface = "bold") +
  facet_wrap(~ metric, ncol = 3, scales = "free_y") +
  scale_x_continuous(breaks = k_range) +
  labs(
    title = "Cluster Selection Metrics by k",
    subtitle = "Ward's D2 hierarchical clustering on 7 dimension z-scores (32 teams)",
    x = "Number of clusters (k)",
    y = NULL
  ) +
  theme_hockey() +
  theme(
    strip.text = element_text(size = 11),
    panel.grid.major.x = element_blank()
  )

# Save
ggsave("outputs/figures/figure3_k_selection.png", p,
       width = 12, height = 4, dpi = 150)

cat("Saved: outputs/figures/figure3_k_selection.png\n")
print(p)
