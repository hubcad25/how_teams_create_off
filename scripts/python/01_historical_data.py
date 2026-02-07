# Download historical MoneyPuck team data (2020-21 to 2024-25)

import requests
import pandas as pd
from datetime import datetime
from io import StringIO
import os


def get_moneypuck_csv_url(season='2020', game_type='regular'):
    """Build MoneyPuck CSV URL."""
    base_url = "https://moneypuck.com/moneypuck/playerData/seasonSummary"
    return f"{base_url}/{season}/{game_type}/teams.csv"


def download_season(season, game_type='regular', situation='5on5'):
    """Download team data for a specific season."""
    csv_url = get_moneypuck_csv_url(season, game_type)

    print(f"Downloading: {csv_url}")
    print(f"  Season: {season}-{int(season)+1}, {game_type}, {situation}")

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }

    response = requests.get(csv_url, headers=headers, timeout=30)
    response.raise_for_status()

    df = pd.read_csv(StringIO(response.text))

    # Filter for 5v5 if situation column exists
    if 'situation' in df.columns and situation != 'all':
        df = df[df['situation'] == situation].copy()

    df['scrape_date'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    df['season_year'] = f"{season}-{int(season)+1}"
    df['game_type'] = game_type

    print(f"  {len(df)} teams, {len(df.columns)} columns")

    return df


def save_season_data(df, season, output_dir='data/historical'):
    """Save season data to CSV."""
    os.makedirs(output_dir, exist_ok=True)

    filename = f"{output_dir}/team_data_{season}.csv"

    df.to_csv(filename, index=False, encoding='utf-8')
    print(f"  Saved: {filename}")

    return filename


def main():
    """Download data for seasons 2020-21 to 2024-25."""
    seasons = ['2020', '2021', '2022', '2023', '2024']

    all_data = []

    for season in seasons:
        print(f"\n{'='*60}")
        print(f"Processing season {season}-{int(season)+1}")
        print('='*60)

        try:
            df = download_season(
                season=season,
                game_type='regular',
                situation='5on5'
            )

            save_season_data(df, season)
            all_data.append(df)

            if 'team' in df.columns:
                print(f"  Teams: {', '.join(sorted(df['team'].unique()))}")

        except Exception as e:
            print(f"  ERROR: {e}")
            continue

    # Summary
    print(f"\n{'='*60}")
    print(f"SUMMARY: Downloaded {len(all_data)}/{len(seasons)} seasons")
    print('='*60)

    for df in all_data:
        season = df['season_year'].iloc[0]
        print(f"  {season}: {len(df)} teams")

    return all_data


if __name__ == "__main__":
    main()
