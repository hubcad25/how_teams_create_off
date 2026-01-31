# Analyse des styles offensifs 5v5 de la LNH (2025-26)

Article Substack pour visualiser et comprendre COMMENT les équipes de la LNH créent de l'attaque à 5 contre 5.

## Source de données
- **URL principale**: https://moneypuck.com/teams.htm (saison 2025-26 en cours)
- **Glossaire**: https://moneypuck.com/glossary.htm
- **Format**: Scraper la table HTML directement

## Méthodologie

### 1. Variables d'input (style de jeu) - Pour la PCA

Ces variables décrivent COMMENT les équipes jouent:

**Quantité/Volume d'attaque:**
- Corsi For (CF) - toutes tentatives de tir
- Fenwick For (FF) - tentatives non-bloquées
- Shots on Goal (SOG)
- Expected Goals For (xGF)

**Qualité/Sélection de tirs:**
- Shooting% on SOG (input car style/sélectivité)
- Shooting% on unblocked shots
- xG per shot (qualité moyenne)
- High Danger Chances For
- Medium Danger Chances For
- Low Danger Chances For

**Création de chances:**
- Rebounds created/recovered
- Takeaways
- Giveaways (négatif)
- Rush attempts
- Off-the-rush shots

**Efficacité des tentatives:**
- Shot attempts blocked (contre nous - négatif)
- Shots that miss the net
- % of net misses above expected

**Discipline:**
- Penalty differential (PIM For - PIM Against)
- Minor penalties taken

### 2. Réduction dimensionnelle: PCA

- **Méthode**: Principal Component Analysis
- **Objectif**: Réduire les ~15-20 variables en 3-5 dimensions interprétables
- **Normalisation**: Standardiser toutes les variables (z-scores) avant PCA
- **Nombre de composantes**: Déterminer avec scree plot + interprétabilité

**Dimensions hypothétiques attendues:**
1. Volume d'attaque (haute pression vs. faible volume)
2. Qualité vs. Quantité (tirs sélectifs vs. "shoot everything")
3. Vitesse/Rush vs. Cycle (jeu de transition vs. possession)
4. Discipline/Chaos (clean vs. pénalités/turnovers)

### 3. Clustering

- **Méthode**: K-means sur les scores PCA
- **Nombre de clusters**: À déterminer (tester 3-6 clusters)
- **Validation**: Silhouette score, interprétabilité

### 4. Variables d'output (résultats)

Ces variables mesurent le SUCCÈS offensif:
- Goals For (GF)
- Goals For % (GF%)
- xGoals For %
- Shooting% (on all unblocked shots)
- High/Medium/Low danger goal ratio

### 5. Visualisations et analyses

1. **Scatterplots des composantes principales** (PC1 vs PC2, etc.)
2. **Clusters d'équipes** colorés sur les PC plots
3. **Heatmap** des variables originales par cluster
4. **Radar charts** des profils moyens par cluster
5. **Scatterplots outputs vs. style**:
   - GF% vs. PC1, PC2, etc.
   - xGF% vs. style dimensions
   - Shooting% vs. shot quality metrics
6. **Modèles prédictifs** (optionnel):
   - Régresser GF% sur les composantes principales
   - Identifier quels styles prédisent le succès

## Stack technique

- **Python**: Scraping des données (BeautifulSoup, requests, pandas)
- **R**: Analyses statistiques et visualisations (tidyverse, FactoMineR, ggplot2)

## Traitement des données

### Données disponibles directement sur moneypuck:
- **Percentages**: xG%, Corsi%, Fenwick%, Shooting%, Save%
- **Comptes bruts**: Goals, Shots, Penalties, Rebounds, Hits, Takeaways, Giveaways
- **Par 60 minutes**: La plupart des métriques (à scraper en mode "Per 60")
- **Par danger**: Low/Medium/High danger shots, goals, xGoals

### Métriques à calculer:

**Qualité de tir:**
- xG per shot = xGF / Unblocked shots
- xG per SOG = xGF / Shots on goal
- High danger shot % = HD shots / Total shots
- Medium danger shot % = MD shots / Total shots
- Low danger shot % = LD shots / Total shots

**Efficacité:**
- Shooting% on unblocked = Goals / Unblocked shots
- Conversion rate by danger level = Goals / Shots (pour HD, MD, LD)
- Blocked shot rate = Blocked shots / Shot attempts (Corsi)
- Missed net rate = Missed shots / Unblocked attempts

**Création/Discipline:**
- Penalty differential per 60 = (Penalties drawn - Penalties taken) per 60
- Takeaway/Giveaway ratio = Takeaways / Giveaways
- Rebound recovery % (si données disponibles)

**Outputs (variables dépendantes):**
- Goals% = GF / (GF + GA)
- xGoals% = xGF / (xGF + xGA)
- Shooting% above expected = Shooting% - (xGF / Shots)

**Normalisation pour PCA:**
- Toutes les variables seront standardisées (z-scores) avant la PCA
- Permet de comparer des métriques sur différentes échelles

## Structure du code

```
/
├── data/
│   ├── raw/              # Données scrapées brutes (CSV)
│   └── processed/        # Données nettoyées/transformées
├── scripts/
│   ├── python/
│   │   └── 01_scrape_data.py
│   └── R/
│       ├── 02_clean_data.R
│       ├── 03_pca_analysis.R
│       ├── 04_clustering.R
│       └── 05_visualizations.R
├── outputs/
│   ├── figures/
│   └── tables/
└── article/
    └── draft.md          # Brouillon Substack
```

## Livrables

1. **Datasets** (CSV) pour reproducibilité
2. **Figures publication-ready** (PNG/SVG haute résolution)
3. **Article Substack** avec visualisations intégrées
4. **Notebook exploratoire** (optionnel) pour les lecteurs techniques

