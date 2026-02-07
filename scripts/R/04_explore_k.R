# Exploration du clustering hiérarchique (Ward)
# Dendrogramme + heatmap des dimensions

library(tidyverse)
library(cluster)
library(clessnize)
library(ggdendro)
library(dendextend)
library(patchwork)

cat("EXPLORATION DU CLUSTERING (WARD)\n\n")

# 1. CHARGEMENT ----

df_dim <- read_csv("data/processed/team_dimension_scores.csv", show_col_types = FALSE)

score_cols <- setdiff(names(df_dim), c("team", "name"))
scores <- df_dim %>% select(all_of(score_cols)) %>% as.matrix()
rownames(scores) <- df_dim$team

cat("Données:", nrow(df_dim), "équipes,", length(score_cols), "dimensions\n")
cat("Dimensions:", paste(score_cols, collapse = ", "), "\n\n")

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

# 2. CLUSTERING HIÉRARCHIQUE (WARD) ----

d <- dist(scores)
hc <- hclust(d, method = "ward.D2")

# Ordre des équipes selon le dendrogramme
team_order <- hc$labels[hc$order]

cat("Ordre du dendrogramme:\n")
cat(paste(team_order, collapse = " → "), "\n\n")

# 3. SILHOUETTE PAR K (coupes du dendrogramme) ----

k_range <- 2:8

sil_results <- tibble(
  k = k_range,
  silhouette = NA_real_,
  sizes = NA_character_
)

for (i in seq_along(k_range)) {
  k <- k_range[i]
  clusters <- cutree(hc, k = k)
  sil <- silhouette(clusters, d)
  sil_results$silhouette[i] <- mean(sil[, 3])
  sil_results$sizes[i] <- paste(sort(table(clusters)), collapse = "-")
}

cat("Silhouette par k (Ward):\n\n")
print(sil_results %>% mutate(silhouette = round(silhouette, 3)))
cat("\n")

# Aperçu des coupes candidates
k_candidates <- c(3, 4, 5, 6)

for (k in k_candidates) {
  clusters <- cutree(hc, k = k)
  cat(sprintf("--- k = %d (silhouette = %.3f) ---\n",
              k, sil_results$silhouette[sil_results$k == k]))

  for (cl in sort(unique(clusters))) {
    teams <- names(clusters[clusters == cl])
    cat(sprintf("  Cluster %d (%d): %s\n", cl, length(teams), paste(teams, collapse = ", ")))
  }
  cat("\n")
}

# 4. DENDROGRAMME + HEATMAP COMBINÉ ----

# Dendrogramme via ggdendro
dend_data <- dendro_data(as.dendrogram(hc), type = "rectangle")

# Labels des équipes dans le dendrogramme
leaf_labels <- label(dend_data)

p_dendro <- ggplot() +
  geom_segment(data = segment(dend_data),
               aes(x = x, y = y, xend = xend, yend = yend),
               linewidth = 0.8, color = "#2c3e50") +
  geom_text(data = leaf_labels,
            aes(x = x, y = y, label = label),
            hjust = 0.5, vjust = 1.5, size = 3.8, fontface = "bold") +
  scale_x_continuous(expand = expansion(add = 0.5)) +
  scale_y_continuous(expand = expansion(mult = c(0.12, 0.05))) +
  labs(title = "Dendrogramme (Ward D2)") +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    plot.margin = margin(5, 5, 0, 5)
  )

# Heatmap ordonnée par le dendrogramme
dim_long <- df_dim %>%
  pivot_longer(cols = all_of(score_cols), names_to = "dimension", values_to = "score") %>%
  mutate(
    team = factor(team, levels = team_order),
    dimension = factor(dimension, levels = score_cols)
  )

# Limites symétriques basées sur le max absolu des données
score_max <- ceiling(max(abs(dim_long$score)) * 10) / 10

p_heat <- ggplot(dim_long, aes(x = as.numeric(team), y = dimension, fill = score)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%.1f", score)), size = 2.3) +
  scale_fill_gradientn(
    colours = c("#08306b", "#2166ac", "#92c5de", "#d1e5f0",
                "white",
                "#fddbc7", "#f4a582", "#b2182b", "#67001f"),
    values = scales::rescale(
      c(-score_max, -score_max*0.75, -score_max*0.45,  -score_max*0.15,
        0,
        score_max*0.15, score_max*0.45, score_max*0.75, score_max),
      to = c(0, 1)
    ),
    limits = c(-score_max, score_max),
    name = "Score"
  ) +
  scale_x_continuous(
    breaks = seq_along(team_order),
    labels = team_order,
    expand = expansion(add = 0.5)
  ) +
  labs(x = NULL, y = NULL) +
  theme_clean_light() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 7),
    axis.text.y = element_text(size = 9),
    panel.grid = element_blank(),
    legend.key.height = unit(0.5, "cm"),
    plot.margin = margin(0, 5, 5, 5)
  )

p_combined <- p_dendro / p_heat +
  plot_layout(heights = c(1, 2))

ggsave("outputs/figures/dendro_heatmap.png", p_combined,
       width = 14, height = 10, dpi = 150)

# 5. DENDROGRAMMES COLORÉS PAR K (3 à 7) ----

dend <- as.dendrogram(hc)

cluster_palettes <- list(
  "3" = c("#e74c3c", "#3498db", "#27ae60"),
  "4" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6"),
  "5" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6", "#f39c12"),
  "6" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6", "#f39c12", "#1abc9c"),
  "7" = c("#e74c3c", "#3498db", "#27ae60", "#9b59b6", "#f39c12", "#1abc9c", "#e91e63")
)

dendro_plots <- map(3:7, function(k) {
  dend_k <- color_branches(dend, k = k, col = cluster_palettes[[as.character(k)]])
  ggd <- as.ggdend(dend_k)

  sil_val <- sil_results$silhouette[sil_results$k == k]
  sizes <- sil_results$sizes[sil_results$k == k]

  ggplot() +
    geom_segment(data = ggd$segments,
                 aes(x = x, y = y, xend = xend, yend = yend, color = col),
                 linewidth = 1) +
    scale_color_identity() +
    geom_text(data = ggd$labels,
              aes(x = x, y = y, label = label),
              hjust = 0.5, vjust = 1.3, size = 4, fontface = "bold") +
    scale_x_continuous(expand = expansion(add = 0.5)) +
    scale_y_continuous(expand = expansion(mult = c(0.15, 0.05))) +
    labs(title = sprintf("k = %d  (sil = %.3f, tailles: %s)", k, sil_val, sizes)) +
    theme_clean_light() +
    theme(
      plot.title = element_text(face = "bold", size = 10),
      axis.text = element_blank(),
      axis.title = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      plot.margin = margin(2, 5, 2, 5)
    )
})

p_all_k <- wrap_plots(dendro_plots, ncol = 1)

ggsave("outputs/figures/dendro_by_k.png", p_all_k,
       width = 14, height = 18, dpi = 150)

# 6. HEATMAP FACET PAR CLUSTER (k=6) ----

K_FACET <- 6
clusters_facet <- cutree(hc, k = K_FACET)

# Nommer les clusters par leur trait dominant
cluster_profiles_facet <- df_dim %>%
  mutate(cluster = clusters_facet) %>%
  group_by(cluster) %>%
  summarise(across(all_of(score_cols), mean), .groups = "drop")

# Label auto: dimension avec le score moyen le plus extrême
cluster_labels <- cluster_profiles_facet %>%
  rowwise() %>%
  mutate(
    scores_vec = list(c_across(all_of(score_cols))),
    top_dim = score_cols[which.max(abs(scores_vec))],
    top_val = scores_vec[which.max(abs(scores_vec))],
    label = sprintf("Cluster %d (%s %s%.1f)",
                    cluster, top_dim,
                    ifelse(top_val > 0, "+", ""), top_val)
  ) %>%
  ungroup() %>%
  select(cluster, label)

facet_long <- df_dim %>%
  mutate(cluster = clusters_facet) %>%
  left_join(cluster_labels, by = "cluster") %>%
  pivot_longer(cols = all_of(score_cols), names_to = "dimension", values_to = "score") %>%
  mutate(
    dimension = factor(dimension, levels = score_cols),
    team = reorder(team, score, FUN = function(x) -mean(x))
  )

p_facet <- ggplot(facet_long, aes(x = dimension, y = team, fill = score)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%.1f", score)), size = 2.5) +
  facet_wrap(~label, scales = "free_y", ncol = 3) +
  scale_fill_gradientn(
    colours = c("#08306b", "#2166ac", "#92c5de",
                "white",
                "#f4a582", "#b2182b", "#67001f"),
    values = scales::rescale(
      c(-score_max, -score_max*0.55, -score_max*0.2,
        0,
        score_max*0.2, score_max*0.55, score_max),
      to = c(0, 1)
    ),
    limits = c(-score_max, score_max),
    name = "Score"
  ) +
  labs(
    title = sprintf("Profils par cluster (k = %d, Ward)", K_FACET),
    x = NULL, y = NULL
  ) +
  theme_clean_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    strip.text = element_text(face = "bold", size = 9),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    axis.text.y = element_text(size = 9),
    panel.grid = element_blank()
  )

ggsave("outputs/figures/heatmap_clusters_k6.png", p_facet,
       width = 16, height = 12, dpi = 150)

# 7. SAUVEGARDE ----

write_csv(sil_results, "outputs/tables/explore_k_results.csv")
saveRDS(hc, "data/processed/hclust_ward.rds")

cat("Fichiers sauvegardés:\n")
cat("  outputs/figures/dendro_heatmap.png\n")
cat("  outputs/figures/dendro_by_k.png\n")
cat("  outputs/figures/heatmap_clusters_k6.png\n")
cat("  outputs/tables/explore_k_results.csv\n")
cat("  data/processed/hclust_ward.rds\n")
