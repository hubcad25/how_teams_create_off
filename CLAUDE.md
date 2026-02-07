# Analyse des styles offensifs 5v5 de la LNH (2025-26)

Article Substack pour visualiser et comprendre COMMENT les équipes de la LNH créent de l'attaque à 5 contre 5.

**IMPORTANT: L'article final sera en ANGLAIS.** Tous les labels, noms de dimensions et visualisations doivent être en anglais.

## Source de données
- **URL principale**: https://moneypuck.com/teams.htm (saison 2025-26 en cours)
- **Glossaire**: https://moneypuck.com/glossary.htm
- **Format**: CSV téléchargé directement depuis l'API moneypuck

## Méthodologie

### 1. Variables d'input (style de jeu)

Ces variables décrivent COMMENT les équipes jouent:

- **Volume**: Corsi/60, Fenwick/60, SOG/60, xG/60, Corsi%, Fenwick%
- **Qualité de tir**: xG/shot, % HD/MD/LD shots, ratios HD/LD, HD/MD, MD/LD
- **Pénétration**: SOG/Corsi, blocked shot rate, missed net rate
- **Rebonds**: Rebounds/60, xG/rebound, % xG from rebounds
- **Misc**: Takeaways, giveaways, penalties, faceoffs, hits, zone exits

### 2. Réduction dimensionnelle: Factor Analysis

- FA à 1 facteur par groupe de variables (7 dimensions)
- Scores standardisés (z-scores) pour comparabilité

**Dimensions:**
1. **Volume** — Shot volume per 60 (Corsi, Fenwick, SOG, xG)
2. **Quality** — Shot selection (xG/shot, HD/MD/LD ratios)
3. **Penetration** — Ability to get shots through (completion rate, blocked/missed rates)
4. **Rebounds** — Second chance creation
5. **Finishing** — Converting vs expected (Sh% vs xSh%, goals above expected)
6. **Recovery+Possession** — Puck recovery (takeaways), limiting giveaways, maintaining zone pressure
7. **Puck exchanges** — Pace of play, turnover frequency (high giveaways+takeways, low hits/penalties)

**Cluster Names (k=6):**
- Cluster 2: High-Octane Drive: Tempo rapide, drive the net, beaucoup de rebonds
- Cluster 6: Puck Hog & Finish: prennent controle de la rondelle aggressivement puis la garde, bons finishers.
- Cluster 4: Selective Shooting: ne tirent pas beaucoup mais qualité, pas beaucoup de traffic, bon finishing.
- Cluster 3: Streaky Offense: ils sont dans la moyenne partout. Ce qui drive performance est le finishing donc très volatil
- Cluster 1: Crash & Hope: vont au filet et récupération un peu aggressive, pas de finish.
- Cluster 5: Lane Creation: créer les lignes de tir de qualité, succès drivé par traffic et puck exchanges

### 3. Clustering

- K-means sur les scores FA
- Sélection du k par silhouette score


### 4. Variables d'output (résultats)

Variables mesurant le SUCCÈS offensif: GF%, xGF%, Sh%, goals above expected, conversion par niveau de danger.

## Stack technique

- **Python**: Scraping (requests, pandas)
- **R**: Analyses statistiques et visualisations (tidyverse, psych, cluster, clessnize, ggplot2)

## Traitement des données

### Métriques calculées dans 02_clean_data.R:

- **Qualité de tir**: xG/shot, xG/SOG, danger shot distributions
- **Efficacité**: Blocked shot rate, missed net rate, shot completion
- **Création**: Rebounds/60, takeaway/giveaway ratio, rebound xG share
- **Discipline**: Penalty differential/60
- **Outputs**: GF%, xGF%, Sh% vs expected, goals above expected, conversion by danger level

Toutes les variables INPUT sont standardisées (z-scores) avant la FA.
