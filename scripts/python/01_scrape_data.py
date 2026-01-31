"""
Script de scraping des données d'équipes NHL depuis moneypuck.com
Saison 2025-26, statistiques 5v5

Le site charge les données depuis un CSV directement :
https://peter-tanner.com/moneypuck/playerData/seasonSummary/{season}/{gameType}/teams.csv
"""

import requests
import pandas as pd
from datetime import datetime
import os

def get_moneypuck_csv_url(season='2025', game_type='regular', situation='5on5'):
    """
    Construit l'URL du CSV moneypuck

    Parameters:
    -----------
    season : str
        Année de début de saison (ex: '2025' pour 2025-26)
    game_type : str
        Type de match ('regular', 'playoffs')
    situation : str
        Type de situation ('5on5', 'all', 'PP', 'PK', etc.)

    Returns:
    --------
    str
        URL du fichier CSV
    """

    base_url = "https://moneypuck.com/moneypuck/playerData/seasonSummary"
    csv_url = f"{base_url}/{season}/{game_type}/teams.csv"

    return csv_url


def download_moneypuck_data(season='2025', game_type='regular', situation='5on5'):
    """
    Télécharge les données d'équipes depuis le CSV moneypuck

    Parameters:
    -----------
    season : str
        Année de début de saison (ex: '2025' pour 2025-26)
    game_type : str
        Type de match ('regular', 'playoffs')
    situation : str
        Type de situation ('5on5', 'all', etc.)

    Returns:
    --------
    pd.DataFrame
        DataFrame avec toutes les statistiques d'équipes
    """

    csv_url = get_moneypuck_csv_url(season, game_type, situation)

    print(f"Téléchargement des données depuis:")
    print(f"  {csv_url}")
    print(f"  Saison: {season}-{int(season)+1}")
    print(f"  Type: {game_type}")
    print(f"  Situation: {situation}")

    # Headers pour imiter un navigateur
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }

    try:
        response = requests.get(csv_url, headers=headers, timeout=30)
        response.raise_for_status()

        # Lire le CSV directement depuis la réponse
        from io import StringIO
        df = pd.read_csv(StringIO(response.text))

        # Filtrer par situation si nécessaire
        # Le CSV contient toutes les situations, on peut filtrer avec la colonne 'situation'
        if 'situation' in df.columns and situation != 'all':
            df = df[df['situation'] == situation].copy()

        # Ajouter metadata
        df['scrape_date'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        df['season_year'] = f"{season}-{int(season)+1}"
        df['game_type'] = game_type

        print(f"✓ Données téléchargées: {len(df)} équipes, {len(df.columns)} colonnes")

        # Afficher les situations disponibles
        if 'situation' in df.columns:
            situations = df['situation'].unique()
            print(f"  Situations disponibles: {', '.join(situations)}")

        return df

    except requests.exceptions.RequestException as e:
        print(f"✗ Erreur de requête: {e}")
        print(f"  Vérifiez que les données pour la saison {season}-{int(season)+1} sont disponibles")
        raise
    except Exception as e:
        print(f"✗ Erreur lors du téléchargement: {e}")
        raise


def save_data(df, filename_prefix='moneypuck_teams', output_dir='../../data/raw'):
    """
    Sauvegarde le DataFrame en CSV avec timestamp

    Parameters:
    -----------
    df : pd.DataFrame
        Données à sauvegarder
    filename_prefix : str
        Préfixe du nom de fichier
    output_dir : str
        Dossier de sortie
    """

    # Créer le dossier si nécessaire
    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f"{output_dir}/{filename_prefix}_{timestamp}.csv"

    # Sauvegarder aussi une version "latest" pour faciliter l'accès
    latest_filename = f"{output_dir}/{filename_prefix}_latest.csv"

    df.to_csv(filename, index=False, encoding='utf-8')
    df.to_csv(latest_filename, index=False, encoding='utf-8')

    print(f"\n✓ Données sauvegardées:")
    print(f"  - {filename}")
    print(f"  - {latest_filename}")

    return filename


def explore_data(df):
    """
    Affiche des informations sur les données téléchargées
    """

    print("\n" + "="*60)
    print("APERÇU DES DONNÉES")
    print("="*60)

    print(f"\nShape: {df.shape}")
    print(f"  {len(df)} équipes")
    print(f"  {len(df.columns)} colonnes")

    print("\n--- Premières lignes ---")
    print(df.head())

    print("\n--- Colonnes disponibles ---")
    cols = df.columns.tolist()
    for i, col in enumerate(cols, 1):
        print(f"{i:3d}. {col}")

    # Vérifier les équipes
    if 'team' in df.columns:
        print(f"\n--- Équipes ({len(df['team'].unique())} équipes) ---")
        teams = sorted(df['team'].unique())
        for team in teams:
            print(f"  - {team}")

    # Stats basiques
    if 'goalsFor' in df.columns and 'goalsAgainst' in df.columns:
        print("\n--- Stats basiques ---")
        print(f"Goals For - Moyenne: {df['goalsFor'].mean():.2f}")
        print(f"Goals Against - Moyenne: {df['goalsAgainst'].mean():.2f}")


def main():
    """
    Fonction principale
    """

    print("="*60)
    print("TÉLÉCHARGEMENT MONEYPUCK.COM - NHL TEAMS 5v5 STATS")
    print("="*60)
    print()

    # Télécharger les données 5v5 de la saison 2025-26
    df_5v5 = download_moneypuck_data(
        season='2025',
        game_type='regular',
        situation='5on5'
    )

    # Explorer les données
    explore_data(df_5v5)

    # Sauvegarder
    print("\n" + "="*60)
    saved_file = save_data(df_5v5, filename_prefix='moneypuck_5v5')

    print("\n✓ Téléchargement terminé avec succès!")
    print("="*60)

    return df_5v5


if __name__ == "__main__":
    main()
