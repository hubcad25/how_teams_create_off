# NHL Offensive Styles Analysis (2025-26)

Analyzes how NHL teams create offense at 5v5 using dimensional reduction and clustering.

## Methodology

1. **Data collection**: Scrape 5v5 team statistics from MoneyPuck
2. **Feature engineering**: Compute derived metrics (shot quality, efficiency rates, creation rates)
3. **Dimensionality reduction**: Factor Analysis to extract 5 interpretable dimensions:
   - Volume (shot quantity, pressure)
   - Quality (shooting%, xG per shot)
   - Penetration (rush attempts, high danger chances)
   - Rebounds (created/recovered)
   - Miscellaneous (discipline, turnovers)
4. **Clustering**: K-means on factor scores to identify team archetypes
5. **Analysis**: Examine relationship between offensive style and success metrics

## Repository Structure

```
.
├── data/
│   ├── raw/              # Scraped CSV data
│   └── processed/        # Cleaned data and analysis results
├── scripts/
│   ├── python/
│   │   └── 01_scrape_data.py
│   └── R/
│       ├── 02_clean_data.R
│       ├── 03_dimension_fa.R
│       ├── 04_clustering.R
│       └── 05_analysis.R
└── outputs/
    ├── figures/
    └── tables/
```

## Usage

1. Scrape data: `python scripts/python/01_scrape_data.py`
2. Run R analysis pipeline in order:
   - `Rscript scripts/R/02_clean_data.R`
   - `Rscript scripts/R/03_dimension_fa.R`
   - `Rscript scripts/R/04_clustering.R`
   - `Rscript scripts/R/05_analysis.R`

## Data Source

All data from [MoneyPuck](https://moneypuck.com/teams.htm) (5v5 statistics, 2025-26 season).

## Stack

- **Python**: requests, pandas
- **R**: tidyverse, psych, cluster, clessnize, ggplot2
