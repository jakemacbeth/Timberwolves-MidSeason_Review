from __future__ import annotations
from typing import Iterable
from nba_api.stats.endpoints import LeagueGameFinder
from sqlalchemy import text
from sqlalchemy.engine import Engine
from src.utils.logger import setup_logger 
from src.utils.nba_utils import call_with_retries

logger = setup_logger(__name__)  


def extract_gameids(season: str) -> list[str]:

    lgf = call_with_retries(lambda: LeagueGameFinder(season_nullable=season, league_id_nullable="00", 
                                                     season_type_nullable="Regular Season"))
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


def upsert_game_ids(engine: Engine, game_ids: Iterable[str], season: str) -> tuple[int, int]:

    ids = [str(gid) for gid in game_ids]
    attempted = len(ids)
    if attempted == 0:
        return 0, 0

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



def load_spine(engine: Engine, season: str) -> None:
    logger.info(f"\n=== Season {season} ===")
    game_ids = extract_gameids(season)
    logger.info(f"Fetched unique game_ids: {len(game_ids)}")

    attempted, inserted = upsert_game_ids(engine, game_ids, season=season)
    logger.info(f"Attempted inserts: {attempted}")
    logger.info(f"New games inserted: {inserted}")

