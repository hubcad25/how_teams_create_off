# R Scripts Organization

Scripts are organized into **analysis** (produce data tables) and **figures** (produce visualizations).

## Analysis Scripts (01-05)

Run in sequence to generate all data tables:

1. `01_clean_data_2025_26.R` - Clean 2025-26 MoneyPuck data, compute metrics
2. `02_clean_data_historical.R` - Clean historical data (2020-21 to 2024-25)
3. `03_analysis_dimension_scores.R` - Factor analysis: 7 orthogonal dimensions
4. `03b_analysis_hierarchical_clustering.R` - Hierarchical clustering (Ward D2)
5. `04_analysis_cluster_assignments.R` - Assign teams to k=6 clusters
6. `05_analysis_apply_clusters_historical.R` - Apply 2025-26 model to history

## Figure Scripts (figure1-12, appendix)

Each produces one visualization figure:

- `figure1_dimensions_heatmap.R` - Heatmap of team offensive profiles
- `figure2_dimensions_parallel.R` - Parallel coordinates plot
- `figure3_dimension_loadings.R` - FA loadings by dimension
- `figure4_dendrogram_k_selection.R` - Dendrograms for k=3-7
- `figure5_dendrogram_heatmap_k6.R` - Dendrogram + heatmap (k=6)
- `figure6_cluster_profiles_bars.R` - Cluster profiles bar chart
- `figure7_teams_by_cluster_profile.R` - Team profiles by cluster
- `figure8_goals_by_cluster_strip.R` - **LEAD VISUAL**: Goals/60 by cluster
- `figure9_regression_effects.R` - Bootstrap regression effects
- `figure10_finishing_vs_goals.R` - Finishing vs Goals/60
- `figure11_cluster_evolution.R` - Cluster evolution 2020-2026
- `figure12_team_trajectories.R` - Team cluster trajectories heatmap

## Appendix

- `appendix_goals_vs_xg_scatter.R` - Goals vs xG scatter (supplementary)

## Outputs

- **Data tables**: `data/processed/`, `data/historical/`, `outputs/tables/`
- **Figures**: `outputs/figures/`

## Naming Convention

- Analysis scripts: `XX_analysis_<name>.R` or `XX_clean_data_<season>.R`
- Figure scripts: `figure<N>_<description>.R`
- Appendix figures: `appendix_<description>.R`
- Output files match script names (e.g., `figure8_...png`)
