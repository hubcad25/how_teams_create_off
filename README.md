# How NHL Teams Create Offense at 5v5 (2025-26)

> Question: How do NHL teams generate offense at 5v5? Traditional stats (GF, xG) tell us **if** a team produces goals or quality chances, but not **how**. This analysis identifies offensive archetypes and reveals which stylistic choices actually predict success.

## Introduction

Traditional offensive stats (GF, xG) measure *results*, not *process*. Two teams can have identical xG/60 but create it in completely different ways.

Instead of asking "how much?", we ask "how?". We decompose offensive style into 6 process dimensions that describe *how* teams create chances, then identify 5 distinct offensive archetypes across the NHL.

![Goals per 60 by cluster](outputs/figures/figure6_goals_strip.png)

## Data & Methodology

Data: MoneyPuck 5v5 statistics, 2025-26 season (32 teams)

Variables organized by dimension: 30+ input variables measuring *how* teams play:
- Shot volume (Corsi, Fenwick, SOG, xG per 60)
- Shot quality (xG/shot, danger ratios HD/MD/LD)
- Penetration (completion rate, blocked/missed)
- Rebounds & second chances
- Miscellaneous: puck recovery (takeaways/giveaways), faceoffs, zone exits, hits

We run a confirmatory factor analysis on each dimension (1 factor per dimension, except Miscellaneous where we force 2 factors). From the factor loadings, we compute dimension scores for each team.

A 7th dimension, *Finishing*, is computed the same way but treated separately: it measures conversion efficiency rather than style, so it's excluded from clustering and used later to assess which archetypes benefit most from strong finishing.

We then apply hierarchical clustering (Ward D2) on the 6 style dimension scores (excluding Finishing). Based on cluster interpretability, we select k=5 archetypes.

## Dimensions

Style dimensions (used for clustering):

| Dimension | What It Measures | Eigenvalue | Variance Explained | Cronbach's α |
|-----------|------------------|------------|-------------------|--------------|
| Volume | Shot quantity, pressure | 5.32 | 88.6% | 0.98 |
| Quality | Shot selection (as a ratio) | 4.19 | 52.4% | 0.87 |
| Penetration | Getting shots through | 1.67 | 55.7% | 0.68 |
| Rebounds | Second chance creation | 1.45 | 48.2% | 0.54 |
| Recovery+Possession | Lots of takeaways, no giveaways, maintain pressure | 1.75 | 21.9% | 0.52 |
| Puck Exchanges | Takeaways + giveaways | 1.62 | 20.2% | 0.52 |

> The Miscellaneous dimension tested better with 2 factors (42.2% vs 21.0% variance explained), so we split it into Recovery+Possession (21.9%) and Puck Exchanges (20.2%).

Intermediate dimension (computed the same way, excluded from clustering):

| Dimension | What It Measures | Eigenvalue | Variance Explained | Cronbach's α |
|-----------|------------------|------------|-------------------|--------------|
| Finishing | Converting vs expected (Sh% vs xSh%, goals above expected) | 3.1 | 62% | 0.86 |

> Finishing is a composite score derived from 5 conversion metrics (shooting percentage vs expected, goals above expected, conversion by danger level). Like the style dimensions, it's computed via single-factor analysis and expressed as a z-score. But it captures *how well* a team converts its chances, not *how* it creates them. Including it in clustering would mix outcomes with style, so we keep it separate and bring it back in subsequent analyses to test which archetypes benefit most from strong finishing.


![Dimension loadings](outputs/figures/figure1_dimension_loadings.png)

The Misc dimension splits into 2 factors:
- Recovery+Possession: lots of takeaways, no giveaways, maintaining pressure
- Puck Exchanges: frequent turnovers (high giveaways+takeaways, low hits/penalties)

Using these loadings as weights, we compute a composite score for each team on every dimension.
Here is how each NHL team profiles across these 7 dimensions in 2025-2026:

![Team offensive profiles](outputs/figures/figure2_dimensions_heatmap.png)

A few scores stand out already.
- Carolina and Colorado have high *Volume* and *Rebounds* scores, suggesting they generate a lot of shots and create second chances.
- Montreal and Ottawa have high *Recovery+Possession* and low *Puck exchanges*, suggesting they win the puck back and keep it rather than trading turnovers.
- Edmonton and LA have high *Quality* and *Penetration*, suggesting they get pucks through to dangerous areas before shooting.
- San Jose has the highest *Quality* score but the lowest *Volume*. Since *Quality* is built from ratios (xG/shot, danger%), this likely reflects a team that shoots less, but selects high-danger opportunities when it does. 

## Creating Offensive Archetypes

With 6 dimension scores per team, we can now group teams that play similarly. We use Ward's D2 hierarchical clustering on the raw z-scores: it minimizes within-cluster variance at each merge, producing compact groups, and the dendrogram lets us inspect how teams relate before choosing k.

### How Many Archetypes?

We select k using a combination of standard Ward D2 metrics (merge height, within-cluster SS, silhouette), but mostly cluster interpretability.

![Cluster selection metrics](outputs/figures/figure3_k_selection.png)

No single k dominates across all three metrics.

- k=4 has low silhouette (0.211) and produces clusters that are too broad.
- k=5 creates a singleton (SJS) and keeps EDM-LAK merged with the NYR-TOR-DAL-PHI-SEA group.
- k=6 has the highest silhouette (0.236), splits EDM-LAK into their own cluster, and keeps SJS as a singleton.
- k=7 fragments further without adding insight (see [Appendix](#appendix) for dendrograms by k).

We start with k=6. Below, the dendrogram paired with a heatmap of dimension scores (same team ordering).

![Dendrogram heatmap k=6](outputs/figures/figure4_dendrogram_heatmap.png)

> Refinement: the k=6 solution produces one singleton (SJS) and one team with negative silhouette (BOS, at -0.22, placed in the cluster with high *Recovery+Possession* scores despite being closer to the peloton on this dimension). We reassign both algorithmically: the negative-silhouette team moves to its nearest neighbor cluster, and the singleton merges into its closest cluster. This yields 5 final archetypes. The process is automatic and reproducible (see code in `04_analysis_cluster_assignments.R`).

### Interpreting and Naming Archetypes

![Team profiles by cluster](outputs/figures/figure5_teams_by_cluster.png)

| Cluster | Archetype Name | Style | Example Teams |
|---------|------|-----------------|---------------|
| **1** | Streaky Offense | Average everywhere, finishing-dependent (volatile) | BOS, BUF, CGY, DET... (14 teams) |
| **2** | High-Octane Drive | Fast tempo, drive the net, lots of rebounds | ANA, CAR, COL, NSH, TBL |
| **3** | Selective Shooting | Low volume but above-average quality | DAL, NYR, PHI, SEA, SJS, TOR |
| **4** | Lane Creation | Create quality shooting lanes | EDM, LAK |
| **5** | Puck Hogging & Recovery | Aggressive puck control, keep possession | MIN, MTL, OTT, UTA |

## [What Drives Success? trouver un titre clair pour cette section]

**What actually drives offensive production?**

We measure success by Goals/60—the purest output metric.

![Goals per 60 by cluster](outputs/figures/figure6_goals_strip.png)

[Interprétation assez in depth]
[High-Octane Drive est le meilleur en moyenne]
[Puck Hog & FInish est le 2e en moyenne]
[Ce sont les 2 seuls clusters qui ont seulement des équipes au-dessus de la moyenne de la ligue]
[Grosse séparations pour Selective Shooting, Streaky Offense et Crash & Hope]
[Lane Creation est difficile à interpréter]

### Separation Within Clusters

[What separates above-average from below-average teams in each cluster?]

**Method:** Bootstrap regression (500 obs/cluster) with cluster-specific interactions

![Regression effects by cluster](outputs/figures/figure7_regression_effects.png)

[Interprétation: à travers tlm: rebounds, finishing les plus importants]
[Puck Hog & Finish: difficile à interpréter évidemment avec 2 équipes, Penetration semble avoir un petit effet positif.]
[Streaky Offense: on voit à quel point le succès est volatile, dépend du finishing]
[Crash & Hope: même chose, dépend bcp du finishing mais aussi du volume]
[High-Octane Drive: dépend beaucoup des rebounds]
[Selective Shooting et Lane Creation: rebounds]

[Est-ce qu'on devrait ensuite montrer descriptivement la relation succès-dimension pour chaque cluster? Avant le test? en Annexe?]

## Do These Styles Exist in Past Seasons?

> Method: Apply the 2025-26 clustering model to historical seasons (assuming the 6 archetypes are stable over time)

![Cluster evolution 2020-2026](outputs/figures/figure8_cluster_evolution.png)

![Team trajectories heatmap](outputs/figures/figure9_team_trajectories.png)


## Next Steps

> Next step: Re-run clustering on all 5 historical seasons + 2025-26 (191 team-seasons) to identify stable offensive archetypes

Questions to explore:

- Do we get similar clusters with more data?
- Which clusters are "real" (stable over time) vs season-specific?
- How do team trajectories look when clusters are defined historically?
- Are the Habs and Sens really creating a new offensive approach?

> Another potential next step: Running a similar analysis on "achieving defense"

Questions to explore:

- Does a relationship exist between the success of an offensive approach and the success of a defensive approach against that style?

## Data & Methods

**Data Source:** [MoneyPuck](https://moneypuck.com/teams.htm) - 5v5 team statistics

**Technical Stack:**

- **Python:** requests, pandas (data scraping)
- **R:** tidyverse, psych, cluster, clessnize, ggplot2 (analysis & viz)

**Outputs:** `outputs/figures/` and `outputs/tables/`

## Appendix

![Dendrogram k-selection](outputs/figures/appendix_dendrograms_by_k.png)

- [Full code in `scripts/`](scripts/)
- [Cluster assignments: `teams_with_scores.csv`](outputs/tables/teams_with_scores.csv)
- [Dimension loadings: `dimension_loadings.csv`](outputs/tables/dimension_loadings.csv)
