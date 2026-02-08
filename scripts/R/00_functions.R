# Custom functions and themes for NHL offensive styles analysis

library(ggplot2)

# ── Cluster reference ─────────────────────────────────────────────────────────

cluster_names <- c(
  "1" = "Streaky Offense",
  "2" = "High-Octane Drive",
  "3" = "Selective Shooting",
  "4" = "Lane Creation",
  "5" = "Puck Hogging & Recovery"
)

cluster_colors <- c(
  "1" = "#738d75",
  "2" = "#1d95cd",
  "3" = "#D4A017",
  "4" = "#9D4EDD",
  "5" = "#ff7048"
)

cluster_descriptions <- c(
  "1" = "Average everywhere, finishing-dependent (volatile)",
  "2" = "Fast tempo, drive the net, lots of rebounds",
  "3" = "Low volume but above-average quality",
  "4" = "Create quality shooting lanes",
  "5" = "Aggressive puck control, keep possession"
)

# Convenience ggplot scales
scale_color_cluster <- function(...) {
  scale_color_manual(values = cluster_colors, labels = cluster_names, ...)
}

scale_fill_cluster <- function(...) {
  scale_fill_manual(values = cluster_colors, labels = cluster_names, ...)
}

#' Custom ggplot2 theme for the project
#'
#' @param base_size Base font size
#' @param base_family Base font family
#'
#' @return A ggplot2 theme object
#' @export
#'
#' @examples
#' p + theme_hockey()
theme_hockey <- function(base_size = 11, base_family = "") {

  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      # Title: bold, left-aligned
      plot.title = element_text(
        face = "bold",
        size = base_size * 1.3,
        hjust = 0,
        colour = "black"
      ),

      # Subtitle: normal, left-aligned
      plot.subtitle = element_text(
        size = base_size * 1,
        hjust = 0,
        colour = "grey40"
      ),

      # Caption: italic, left-aligned, grey
      plot.caption = element_text(
        face = "italic",
        size = base_size * 0.8,
        hjust = 0,
        colour = "grey50"
      ),

      # Strip text: plain (not bold)
      strip.text = element_text(
        face = "plain",
        size = base_size * 0.9
      ),
      strip.background = element_blank(),

      # Panel grid: major only, thin grey
      panel.grid.major = element_line(
        colour = "grey85",
        linewidth = 0.3
      ),
      panel.grid.minor = element_blank(),

      # No axis ticks
      axis.ticks = element_blank(),

      # Panel border: thin grey
      panel.border = element_rect(
        colour = "grey65",
        fill = NA,
        linewidth = 0.45
      ),

      # White background
      panel.background = element_rect(fill = "white", colour = NA),
      plot.background = element_rect(fill = "white", colour = NA),

      # Legend at bottom
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = base_size * 0.85),
      legend.ticks = element_blank()
    )
}
