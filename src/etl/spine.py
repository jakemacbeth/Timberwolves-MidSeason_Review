from __future__ import annotations

from typing import Iterable
from sqlalchemy import text
from nba_api.stats.endpoints import LeagueGameFinder

from src.db.engine import get_engine

from src.db.engine import get_engine
from src.utils.logger import setup_logger 

from nba_api.stats.endpoints import LeagueGameFinder
from nba_api.library.http import NBAHTTP

logger = setup_logger(__name__)  

# Mimic a real browser so stats.nba.com doesn't block 

_nba_headers = {
    'User-Agent': (
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Safari/537.36'
    ),
    'Referer': 'https://www.nba.com/',
    'Origin': 'https://www.nba.com',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9',
    'x-nba-stats-origin': 'stats',
    'x-nba-stats-token': 'true',
}
NBAHTTP.headers = _nba_headers

def extract_gameids(season: str) -> list[str]:

    lgf = LeagueGameFinder(
        season_nullable=season,
        league_id_nullable="00",
        season_type_nullable="Regular Season"
    )
    df = lgf.get_data_frames()[0]
    df = df[df["WL"].notna()]

    if "GAME_ID" not in df.columns:
        raise ValueError(f"Expected GAME_ID column. Got columns: {list(df.columns)}")

    game_ids = (
        df["GAME_ID"]
        .dropna()
        .astype(str)
        .drop_duplicates()
        .tolist()
    )
    return game_ids


def upsert_game_ids(game_ids: Iterable[str], season: str) -> tuple[int, int]:

    ids = [str(gid) for gid in game_ids]
    attempted = len(ids)
    if attempted == 0:
        return 0, 0

    engine = get_engine()

    insert_sql = text("""
        WITH incoming AS (
            SELECT unnest(:game_ids) AS game_id
        )
        INSERT INTO nba.spine (game_id, season)
        SELECT game_id, :season
        FROM incoming
        ON CONFLICT (game_id) DO NOTHING
        RETURNING game_id;
    """)

    with engine.begin() as conn:
        result = conn.execute(insert_sql, {"game_ids": ids, "season": season})
        inserted = len(result.fetchall())

    return attempted, inserted



def load_seasons(season: str) -> None:
        logger.info(f"\n=== Season {season} ===")
        game_ids = extract_gameids(season)
        logger.info(f"Fetched unique game_ids: {len(game_ids)}")

        attempted, inserted = upsert_game_ids(game_ids, season=season)
        logger.info(f"Attempted inserts: {attempted}")
        logger.info(f"New games inserted: {inserted}")

