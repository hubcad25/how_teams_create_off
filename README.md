# How NHL Teams Create Offense at 5v5 (2025-26)

> Question: How do NHL teams generate offense at 5v5? Traditional stats (GF, xG) tell us **if** a team produces goals or quality chances, but not **how**. This analysis identifies offensive archetypes and reveals which stylistic choices actually predict success.

---

## Introduction

**The Problem:** Traditional offensive stats (GF, xG) measure *results*, not *process*. Two teams can have identical xG/60 but create it in completely different ways.

**Our Approach:** Instead of asking "how much?", we ask "how?". We decompose offensive style into 7 independent dimensions, then identify 6 distinct archetypes that represent the spectrum of NHL offensive philosophies in the 2025-2026 season.

**Lead Visual:** `06_goals_strip.png` - The 6 offensive archetypes visualized by their output

---

## Data & Methodology

[rester concis, textuel, court ici, on veut juste rapidement dire ce qu'on va faire et comment.]

**Data:** MoneyPuck 5v5 statistics, 2025-26 season (32 teams)

**Variables:** 30+ input variables measuring *how* teams play:
- Shot volume (Corsi, Fenwick, SOG, xG per 60)
- Shot quality (xG/shot, danger ratios HD/MD/LD)
- Penetration (completion rate, blocked/missed)
- Rebounds & second chances
- Puck recovery (takeaways/giveaways)
- Faceoffs, zone exits, hits

**Pipeline:**
1. **Factor Analysis** (1 factor per dimension) → 7 orthogonal dimensions. Confirmatoire, guidée par des intuitions/concepts connus
2. **Hierarchical clustering** (Ward dendogram, k=6) → 6 offensive archetypes

---

## Dimensions

| Dimension | What It Measures | Key Variables |
|-----------|------------------|---------------|
| **Volume** | Shot quantity, pressure | Corsi/60, Fenwick/60, SOG/60, xG/60 |
| **Quality** | Shot selection | xG/shot, HD/MD/LD ratios |
| **Penetration** | Getting shots through | SOG/Corsi, blocked rate, missed rate |
| **Rebounds** | Second chance creation | Rebounds/60, rebound xG share |
| **Finishing** | Converting vs expected | Sh% vs xSh%, goals above expected |
| **Recovery+Possession** | Puck recovery, maintaining pressure | Takeaways, giveaways, zone exits |
| **Puck Exchanges** | Pace, turnover frequency | Giveaways+takeaways, penalties, hits |


[dans le tableau, on devrait pas parler de Misc avant de les nommer? Puis les nommer après les loadings?]
[Expliquer qu'on teste 2 facteurs dans la dimension Misc?]

Image: 03_dimension_loadings.png

[interprétation, nommer les 2 dimensions Misc]

Image: 03_dimensions_heatmap.png (en accentuant les valeurs extrêmes)

[texte d'interprétation]

---

## Creating Offensive Archetypes

### How Many Archetypes?

Image: 04_dendrogram_k.png

[interprétation rapide, pcq on peut pas "comprendre" les clusters ici]

Image: 04_dendrogram_heatmap.png [Mais avec dendro coloré k=6]

[Donc ici on interprète les clusters selon k=6 et la heatmap en-dessous. Séparer la heatmap par cluster avec facet wrap]

[Mettre le même graph pour les autres k en annexe]

### Interpreting and Naming Archetypes

Image: 06_teams_by_cluster.png [renommer le graph. garder les noms des clusters dans le graph]

[Interprétation rapide]

| Cluster | Name | Style Signature | Example Teams |
|---------|------|-----------------|---------------|
| **1** | Crash & Hope | High volume + rebounds, poor finishing | CBJ, CHI, MIN, NSH, UTA, VAN |
| **2** | High-Octane Drive | Extreme volume + rebounds, tempo-driven | ANA, CAR, COL, TBL |
| **3** | Streaky Offense | Average everywhere, performance driven by finishing | BOS, DET, NJD, PIT... (12 teams) |
| **4** | Selective Shooting | Low volume, elite shot quality, efficient | DAL, PHI, SEA, SJS, TOR |
| **5** | Lane Creation | Exceptional penetration, creates high-quality lanes | EDM, LAK, NYR |
| **6** | Puck Hog & Finish | Elite recovery + above-expected finishing | MTL, OTT |

---

## [What Drives Success? trouver un titre clair pour cette section]

[What are the better archetypes? What drives success?]

[On va voir comment avec une variable dépendante qui est purement l'output principal: Goals per 60]

Graphique principal: 06_goals_strip.png

[Interprétation assez in depth]
[High-Octane Drive est le meilleur en moyenne]
[Puck Hog & FInish est le 2e en moyenne]
[Ce sont les 2 seuls clusters qui ont seulement des équipes au-dessus de la moyenne de la ligue]
[Grosse séparations pour Selective Shooting, Streaky Offense et Crash & Hope]
[Lane Creation est difficile à interpréter]

### Separation Within Clusters

[What separates above-average from below-average teams in each cluster?]

[Test: bootstrap regression within each clusters (interaction)]
[Explication de la méthode]

Image: 06_regression_effects.png [en colorant pour significativité aussi, on veut vraiment que les effets importants et significatifs sortent]

[Interprétation: à travers tlm: rebounds, finishing les plus importants]
[Puck Hog & Finish: difficile à interpréter évidemment avec 2 équipes, Penetration semble avoir un petit effet positif.]
[Streaky Offense: on voit à quel point le succès est volatile, dépend du finishing]
[Crash & Hope: même chose, dépend bcp du finishing mais aussi du volume]
[High-Octane Drive: dépend beaucoup des rebounds]
[Selective Shooting et Lane Creation: rebounds]

[Est-ce qu'on devrait ensuite montrer descriptivement la relation succès-dimension pour chaque cluster? Avant le test? en Annexe?]

---

## Do These Styles Exist in Past Seasons?

> Method: Apply the 2025-26 clustering model to historical seasons (assuming the 6 archetypes are stable over time)

[explication rapide de comment on s'y prend]

[On pensera à quelles graphs mettre plus tard]

---

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

---

## Data & Methods

**Data Source:** [MoneyPuck](https://moneypuck.com/teams.htm) - 5v5 team statistics

**Technical Stack:**

- **Python:** requests, pandas (data scraping)
- **R:** tidyverse, psych, cluster, clessnize, ggplot2 (analysis & viz)

**Outputs:** `outputs/figures/` and `outputs/tables/`

---

## Appendix

- [Full code in `scripts/`](scripts/)
- [Cluster assignments: `teams_with_scores.csv`](outputs/tables/teams_with_scores.csv)
- [Dimension loadings: `dimension_loadings.csv`](outputs/tables/dimension_loadings.csv)
