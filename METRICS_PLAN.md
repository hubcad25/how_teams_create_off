# Plan des métriques et ratios - Analyse 5v5

## Définitions clés (Glossaire MoneyPuck)

**xGoals (Expected Goals)**: Probabilité qu'une tentative de tir non-bloquée devienne un but. Assume une habileté de tir moyenne. Ex: rebond dans l'enclave = 0.5 xG, tir de la ligne bleue en désavantage = 0.01 xG.

**Corsi**: TOUTES les tentatives de tir = Shots on Goal + Missed Shots + Blocked Shots

**Fenwick**: Tentatives NON-BLOQUÉES = Shots on Goal + Missed Shots (exclut blocked)

**Niveaux de danger** (pour shots non-bloqués):
- **Low Danger**: <8% probabilité de but (~75% des tirs, ~33% des buts)
- **Medium Danger**: 8-20% probabilité (~20% des tirs, ~33% des buts)
- **High Danger**: 20%+ probabilité (~5% des tirs, ~33% des buts)

---

## Données brutes disponibles (déjà dans le CSV)

### Variables à utiliser (RAW, pas d'ajustement):
- `xGoalsPercentage` - xG%
- `corsiPercentage` - Corsi%
- `fenwickPercentage` - Fenwick%
- `iceTime` - Temps de glace total (en secondes)
- Toutes les variables "For" (pas de "Against" pour l'instant)

---

## MÉTRIQUES À CALCULER

### 1. VOLUME/QUANTITÉ D'ATTAQUE (inputs PCA)

**Taux par 60 minutes:**
```
shotAttemptsFor_per60 = (shotAttemptsFor / iceTime) * 3600
unblockedShotAttemptsFor_per60 = (unblockedShotAttemptsFor / iceTime) * 3600
shotsOnGoalFor_per60 = (shotsOnGoalFor / iceTime) * 3600
xGoalsFor_per60 = (xGoalsFor / iceTime) * 3600
```

**Métriques de volume:**
- Corsi%, Fenwick%, xG% (déjà disponibles)
- Shot attempts per 60
- Shots on goal per 60
- xGoals per 60

---

### 2. QUALITÉ/SÉLECTION DE TIRS (inputs PCA)

**Qualité moyenne des tentatives:**
```
xG_per_shotAttempt = xGoalsFor / shotAttemptsFor
xG_per_unblockedShot = xGoalsFor / unblockedShotAttemptsFor
xG_per_SOG = xGoalsFor / shotsOnGoalFor
```

**Distribution par niveau de danger (% du total):**
```
pct_highDanger = highDangerShotsFor / (lowDangerShotsFor + mediumDangerShotsFor + highDangerShotsFor)
pct_mediumDanger = mediumDangerShotsFor / (lowDangerShotsFor + mediumDangerShotsFor + highDangerShotsFor)
pct_lowDanger = lowDangerShotsFor / (lowDangerShotsFor + mediumDangerShotsFor + highDangerShotsFor)
```

**Ratios de danger (intensité de sélection):**
```
ratio_HD_LD = highDangerShotsFor / lowDangerShotsFor
ratio_HD_MD = highDangerShotsFor / mediumDangerShotsFor
ratio_MD_LD = mediumDangerShotsFor / lowDangerShotsFor
```
- Ces ratios capturent à quel point une équipe privilégie les tirs de haute qualité vs faible qualité

**Note:** Shooting percentage déplacé vers OUTPUT (c'est de la conversion, pas du style)

---

### 3. EFFICACITÉ DES TENTATIVES (inputs PCA)

**Taux de complétion des tirs:**
```
shot_completion_rate = shotsOnGoalFor / shotAttemptsFor
unblocked_rate = unblockedShotAttemptsFor / shotAttemptsFor
```

**Taux d'échec (négatifs):**
```
blocked_shot_rate = blockedShotAttemptsFor / shotAttemptsFor
missed_net_rate = missedShotsFor / unblockedShotAttemptsFor
```

**Net misses above/below expected:**
- Nécessite un modèle de référence ou moyenne de ligue
- Pour l'instant, utiliser simplement `missed_net_rate` comme proxy

---

### 4. CRÉATION DE CHANCES (inputs PCA)

**Taux par 60:**
```
rebounds_per60 = (reboundsFor / iceTime) * 3600
takeaways_per60 = (takeawaysFor / iceTime) * 3600
giveaways_per60 = (giveawaysFor / iceTime) * 3600
```

**Ratios:**
```
takeaway_giveaway_ratio = takeawaysFor / giveawaysFor
```

**Qualité des rebonds créés:**
```
xG_per_rebound = reboundxGoalsFor / reboundsFor
```
- Mesure si les rebonds créés sont dans des positions dangereuses

**Part du danger venant des rebonds:**
```
pct_xG_from_rebounds = reboundxGoalsFor / xGoalsFor
```

---

### 5. DISCIPLINE (inputs PCA)

**Différentiels par 60:**
```
penalty_differential_per60 = ((penaltiesAgainst - penaltiesFor) / iceTime) * 3600
PIM_differential_per60 = ((penalityMinutesAgainst - penalityMinutesFor) / iceTime) * 3600
```

**Taux individuels:**
```
penalties_taken_per60 = (penaltiesFor / iceTime) * 3600
penalties_drawn_per60 = (penaltiesAgainst / iceTime) * 3600
```

---

### 6. STYLE DE JEU (inputs PCA - optionnel/exploratoire)

**Contrôle de zone:**
```
zone_exit_success = playContinuedOutsideZoneFor / (playContinuedOutsideZoneFor + playContinuedInZoneFor)
```

**Intensité physique:**
```
hits_per60 = (hitsFor / iceTime) * 3600
```

**Faceoffs:**
```
faceoff_win_pct = faceOffsWonFor / (faceOffsWonFor + faceOffsWonAgainst)
```

---

## VARIABLES DE SORTIE (OUTPUTS - pas dans PCA)

### 7. RÉSULTATS/SUCCÈS OFFENSIF

**Buts:**
```
goals_per60 = (goalsFor / iceTime) * 3600
goals_pct = goalsFor / (goalsFor + goalsAgainst)
```

**Expected Goals:**
```
xGoals_pct = xGoalsFor / (xGoalsFor + xGoalsAgainst)
```

**Shooting percentage (conversion globale):**
```
shooting_pct_SOG = goalsFor / shotsOnGoalFor
shooting_pct_unblocked = goalsFor / unblockedShotAttemptsFor
shooting_pct_attempts = goalsFor / shotAttemptsFor
```

**Shooting performance vs expected:**
```
shooting_pct_vs_expected = (goalsFor / shotsOnGoalFor) - (xGoalsFor / shotsOnGoalFor)
goals_above_expected = goalsFor - xGoalsFor
```

**Ratio GF%/xG% (finishing vs qualité des chances):**
```
GF_pct = goalsFor / (goalsFor + goalsAgainst)
xG_pct = xGoalsFor / (xGoalsFor + xGoalsAgainst)
ratio_GF_xG = GF_pct / xG_pct
```
- Si >1: équipe surperforme son xG (bon finishing ou bon goaltending adverse)
- Si <1: équipe sous-performe son xG (mauvais finishing ou bon goaltending adverse)
- Note: Nécessite "Against" pour ce ratio seulement

**Conversion des rebonds (OUTPUTS):**
```
rebound_goals_per60 = (reboundGoalsFor / iceTime) * 3600
rebound_conversion = reboundGoalsFor / reboundsFor
```

**Par niveau de danger:**
```
goals_highDanger = highDangerGoalsFor
goals_mediumDanger = mediumDangerGoalsFor
goals_lowDanger = lowDangerGoalsFor

# Distribution des buts
pct_goals_highDanger = highDangerGoalsFor / goalsFor
pct_goals_mediumDanger = mediumDangerGoalsFor / goalsFor
pct_goals_lowDanger = lowDangerGoalsFor / goalsFor
```

**Conversion par niveau de danger (OUTPUTS):**
```
shooting_pct_HD = highDangerGoalsFor / highDangerShotsFor
shooting_pct_MD = mediumDangerGoalsFor / mediumDangerShotsFor
shooting_pct_LD = lowDangerGoalsFor / lowDangerShotsFor
```

**Sur/sous-performance par danger (OUTPUTS):**
```
HD_goals_vs_xG = highDangerGoalsFor / highDangerxGoalsFor
MD_goals_vs_xG = mediumDangerGoalsFor / mediumDangerxGoalsFor
LD_goals_vs_xG = lowDangerGoalsFor / lowDangerxGoalsFor
```
- Ratio >1 = surperforme xG à ce niveau de danger
- Ratio <1 = sous-performe xG à ce niveau de danger

---

## RÉSUMÉ DES CATÉGORIES POUR LA PCA

### Variables INPUT (style de jeu) - à inclure dans PCA:

**Dimension 1: Volume d'attaque**
1. shotAttemptsFor_per60
2. unblockedShotAttemptsFor_per60
3. shotsOnGoalFor_per60
4. xGoalsFor_per60
5. corsiPercentage
6. fenwickPercentage

**Dimension 2: Qualité/Sélection**
7. xG_per_shotAttempt
8. xG_per_unblockedShot
9. pct_highDanger
10. pct_mediumDanger
11. ratio_HD_LD (high danger / low danger shots)
12. ratio_HD_MD (high danger / medium danger shots)
13. ratio_MD_LD (medium danger / low danger shots)

**Dimension 3: Efficacité/Complétion**
14. shot_completion_rate
15. blocked_shot_rate (négatif)
16. missed_net_rate (négatif)

**Dimension 4: Création**
17. rebounds_per60
18. xG_per_rebound (qualité des rebonds créés)
19. pct_xG_from_rebounds
20. takeaways_per60
21. giveaways_per60 (négatif)
22. takeaway_giveaway_ratio

**Dimension 5: Discipline**
23. penalty_differential_per60
24. penalties_taken_per60

**Optionnel:**
25. faceoff_win_pct
26. hits_per60
27. zone_exit_success

---

### Variables OUTPUT (résultats/conversion) - à analyser APRÈS la PCA:

**Buts globaux:**
1. goals_per60
2. goals_pct (GF%)
3. xGoals_pct (xGF%)
4. ratio_GF_xG (GF% / xGF% - finishing performance)

**Shooting percentage (conversion globale):**
5. shooting_pct_SOG
6. shooting_pct_unblocked
7. shooting_pct_attempts
8. shooting_pct_vs_expected
9. goals_above_expected

**Distribution des buts:**
10. pct_goals_highDanger
11. pct_goals_mediumDanger
12. pct_goals_lowDanger

**Conversion des rebonds:**
13. rebound_goals_per60
14. rebound_conversion

**Conversion par niveau de danger:**
15. shooting_pct_HD
16. shooting_pct_MD
17. shooting_pct_LD
18. HD_goals_vs_xG
19. MD_goals_vs_xG
20. LD_goals_vs_xG

---

## NOTES IMPORTANTES

1. **Normalisation per 60**: Tous les comptages doivent être normalisés par temps de glace (iceTime en secondes, multiplier par 3600)

2. **Standardisation**: Toutes les variables INPUT seront standardisées (z-scores) avant PCA

3. **Shooting%**: Traité comme OUTPUT (c'est de la conversion, pas du style)

4. **Nombre de variables INPUT**: ~24-27 variables pour PCA
   - 6 volume + 7 qualité + 3 efficacité + 6 création + 2 discipline + 3 optionnels

5. **Nombre de variables OUTPUT**: 20 variables de résultats/conversion

6. **Correlation check**: Important de vérifier multicolinéarité avant PCA
   - Ex: Corsi% et Fenwick% très corrélés (Fenwick exclut juste les blocked)
   - Peut-être garder juste Fenwick% ou Corsi%?
   - pct_highDanger + pct_mediumDanger + pct_lowDanger = 100% (redondance)

7. **Variables "Against"**: Minimiser leur usage
   - Seulement pour ratio_GF_xG (output)
   - Pas dans les inputs PCA

---

## DÉCISIONS PRISES

1. **Variables "Against"**: ✓ Pas pour l'instant, focus sur "For" (style offensif)
   - Exception: xGoalsAgainst et goalsAgainst nécessaires pour ratio_GF_xG (output seulement)

2. **Score-adjusted metrics**: ✓ NON, utiliser les raw metrics
   - On garde les choses simples, pas d'ajustement score

3. **Flurry/Venue adjustments**: ✓ NON, utiliser xGoalsFor de base
   - Pas de flurryAdjusted, pas de scoreVenueAdjusted

4. **Rebounds**: ✓ Utiliser
   - `reboundsFor` (count)
   - `reboundGoalsFor` (conversion)
   - `reboundxGoalsFor` (expected value from rebounds)

5. **Ratios de danger**: ✓ Ajouter HD/LD, HD/MD, MD/LD
   - Capturent la philosophie de sélection de tirs

6. **GF%/xG%**: ✓ Ajouter comme OUTPUT
   - Ratio qui mesure le finishing vs qualité des chances

7. **Conversion = OUTPUT**: ✓ Toute métrique de conversion est un OUTPUT
   - Inclut: rebound_conversion, shooting_pct par danger, goals_vs_xG par danger
   - Rationale: la conversion mesure un RÉSULTAT (combien tu scores), pas un STYLE (comment tu joues)
   - Les INPUTs mesurent la création/qualité des chances, pas leur conversion en buts



# DIMENSIONS

Volume
   - xG est une mesure qui combine qualité et volume... on fait quoi avec? I guess volume aussi.

Qualité des tentatives
   - ici on devrait pt vraiment se limiter aux ratios qualité/fréquence? Comme ça on isole vraiment la qualité/patience?

Efficacité des tentatives/pénétration
   - Ici on veut juste savoir si l'équipe est capable de mettre la rondelle au filet quand elle tire.
   - % blocked, %missed etc.
   - Donc, encore une fois juste des ratios

Miscellenaous
   - Takeaways, giveaways, penalités, hits, faceoff, zone exit
   - On va checker quoi faire avec les restants: pt essayer des FA à 1-2-3-4 facteurs?

Rebound on rentre ça où? dimension séparée? dans Volume?