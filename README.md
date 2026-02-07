# How NHL Teams Create Offense at 5v5 (2025-26)

> **Question**: How do the best NHL teams generate offense at 5v5? Traditional stats (GF, xG) tell us **if** a team produces, but not **how**. This analysis identifies 6 distinct offensive archetypes and reveals which stylistic choices actually predict success.

---

## 1. Introduction & Hook

- Question ouverture : "Comment les meilleures équipes de la LNH créent-elles de l'attaque à 5v5 ?"
- Problème : Les stats traditionnelles (GF, xG) nous disent **si** une équipe produit, mais pas **comment**
- Notre approche : Analyser le **style** de jeu, pas juste les résultats
- Image lead : `cluster_scatter_main.png` (visualisation des clusters)

## 2. Methodology

- Source de données : MoneyPuck 2025-26
- Notre pipeline :
  - 30+ variables de "style" (comment elles jouent)
  - Factor Analysis → 7 dimensions indépendantes
  - K-means clustering → identification des archétypes
- Graphique : `dimension_loadings.png` (les 7 dimensions expliquées)

## 3. The 7 Dimensions of Offensive Style

- **Volume** — Shot quantity, pressure (Corsi/60, Fenwick/60, SOG/60, xG/60, possession metrics)
- **Quality** — Shot selection (xG/shot, HD/MD/LD ratios, danger shot distribution)
- **Penetration** — Getting shots through vs blocked/missed (completion rate)
- **Rebounds** — Second chance creation (rebounds/60, xG from rebounds)
- **Finishing** — Converting vs expected (Sh% vs xSh%, goals above expected)
- **Recovery+Possession** — Puck recovery (takeaways), limiting giveaways, maintaining zone pressure
- **Puck Exchanges** — Pace of play, turnover frequency (high giveaways+takeways, low hits/penalties)

Visuel : `explore_dim_parallel.png` (parallel coordinates plot)

## 4. Choosing the Number of Clusters (k=6)

- Elbow plot : `explore_k_elbow.png`
- Silhouette analysis : `explore_k_silhouette.png` + `clustering_silhouette.png`
- Justification : Pourquoi k=6 est optimal

## 5. The 6 Offensive Archetypes of 2025-26 ⭐

### Overview Table

| Cluster | Name | Teams | Style |
|---------|------|-------|-------|
| 1 | **Volume Underperformers** | CBJ, CHI, MIN, NSH, UTA, VAN | High volume + rebounds, poor finishing |
| 2 | **High-Volume Creators** | ANA, CAR, COL, TBL | Extreme volume + rebounds, average finishing |
| 3 | **Middle of the Road** | 12 teams (BOS, DET, NJD, PIT...) | Balanced profile |
| 4 | **Selective Efficiency** | DAL, PHI, SEA, SJS, TOR | Low volume, elite shot quality |
| 5 | **Elite Penetrators** | EDM, LAK, NYR | Exceptional penetration (shots through) |
| 6 | **Finishing Specialists** | MTL, OTT | Elite recovery + above-expected finishing |

### For Each Cluster:
- **Nom évocateur** and team list
- **Stylistic profile** (scores on 7 dimensions)
- **Performance** : GF%, goals vs expected
- **Key insight** : What makes this style unique

**Visuals:**
- `cluster_spider.png` — Spider charts for all 6 archetypes
- `cluster_bars.png` — Mean profiles by cluster
- `cluster_heatmap.png` — Heatmap: teams × dimensions
- `cluster_strip_goals.png` — GF% vs xGF% by team

## 6. What Predicts Offensive Success?

- Regression: Which dimensions correlate most with GF%?
- Insight: Finishing > Volume > Quality > Rebounds
- Nuance by cluster: Importance varies by style
- Graph: `cluster_sim_effects.png` (effects by dimension)

## 7. Case Studies (3 Striking Examples)

### Case 1: San Jose (Cluster 4) — Quality > Quantity
- Volume très faible (-1.83 σ)
- Qualité de tir extrême (+3.36 σ)
- Comment ? Sélection ultra-sélective des tirs

### Case 2: Montréal & Ottawa (Cluster 6) — Finishing as a Weapon
- Finishing +1.5 to +1.9 σ (league best)
- Recovery élite
- Moins de volume, conversion exceptionnelle

### Case 3: Edmonton (Cluster 5) — The McDavid/Draisaitl Penetration
- Pénétration +2.8 σ (best in league)
- Qualité +2.6 σ
- Style star-driven : accès direct aux high danger areas

## 8. Conclusions & Takeaways

- There is no **single** way to create offense
- 6 valid paths to offensive success
- Volume isn't everything (Cluster 4 overperforms with few shots)
- Finishing separates good from great (Clusters 5, 6)
- Implications for coaches/GMs: Recruit based on your identity

## 9. Technical Appendix

- Détail des loadings : `dimension_loadings.csv`
- Assignation complète des équipes : `teams_with_scores.csv`
- Code disponible dans `scripts/`

---

## Data Source

All data from [MoneyPuck](https://moneypuck.com/teams.htm) (5v5 statistics, 2025-26 season).

## Stack

- **Python**: requests, pandas
- **R**: tidyverse, psych, cluster, clessnize, ggplot2
