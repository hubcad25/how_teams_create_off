# Scraping des données d'équipes NHL depuis moneypuck.com
# Saison 2025-26, statistiques 5v5

import requests
import pandas as pd
from datetime import datetime
from io import StringIO
import os


def get_moneypuck_csv_url(season='2025', game_type='regular'):
    """Construit l'URL du CSV moneypuck."""
    base_url = "https://moneypuck.com/moneypuck/playerData/seasonSummary"
    return f"{base_url}/{season}/{game_type}/teams.csv"


def download_moneypuck_data(season='2025', game_type='regular', situation='5on5'):
    """Télécharge les données d'équipes depuis le CSV moneypuck."""
    csv_url = get_moneypuck_csv_url(season, game_type)

    print(f"Téléchargement: {csv_url}")
    print(f"  Saison: {season}-{int(season)+1}, {game_type}, {situation}")

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }

    response = requests.get(csv_url, headers=headers, timeout=30)
    response.raise_for_status()

    df = pd.read_csv(StringIO(response.text))

    # Le CSV contient toutes les situations, filtrer
    if 'situation' in df.columns and situation != 'all':
        df = df[df['situation'] == situation].copy()

    df['scrape_date'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    df['season_year'] = f"{season}-{int(season)+1}"
    df['game_type'] = game_type

    print(f"  {len(df)} équipes, {len(df.columns)} colonnes")

    return df


def save_data(df, filename_prefix='moneypuck_teams', output_dir='../../data/raw'):
    """Sauvegarde le DataFrame en CSV avec timestamp + latest."""
    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f"{output_dir}/{filename_prefix}_{timestamp}.csv"
    latest_filename = f"{output_dir}/{filename_prefix}_latest.csv"

    df.to_csv(filename, index=False, encoding='utf-8')
    df.to_csv(latest_filename, index=False, encoding='utf-8')

    print(f"  Sauvegardé: {filename}")
    print(f"  Sauvegardé: {latest_filename}")

    return filename


def explore_data(df):
    """Affiche un aperçu des données téléchargées."""
    print(f"\nShape: {df.shape} ({len(df)} équipes, {len(df.columns)} colonnes)")
    print(df.head())

    if 'team' in df.columns:
        print(f"\n{len(df['team'].unique())} équipes: {', '.join(sorted(df['team'].unique()))}")


def main():
    df_5v5 = download_moneypuck_data(
        season='2025',
        game_type='regular',
        situation='5on5'
    )

    explore_data(df_5v5)
    save_data(df_5v5, filename_prefix='moneypuck_5v5')

    return df_5v5


if __name__ == "__main__":
    main()
