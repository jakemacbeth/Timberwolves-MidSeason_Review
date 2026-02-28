from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime, timedelta

from sqlalchemy import text
from sqlalchemy.engine import Engine
from nba_api.stats.endpoints import leaguedashlineups

from src.utils.nba_utils import call_with_retries
from src.etl.parsing_utils import parse_int, parse_float
from src.utils.logger import setup_logger

logger = setup_logger(__name__)


@dataclass
class GameLineupRow:
    # Game-level lineup performance data
    
    game_id: str 
    game_date: str
    season: str
    team_id: int
    group_quantity: int
    group_id: str
    group_name: Optional[str]
    opponent_team_id: Optional[int]
    is_home: Optional[bool]
    min: Optional[float]
    plus_minus: Optional[int]
    pts: Optional[int]
    fgm: Optional[int]
    fga: Optional[int]
    fg_pct: Optional[float] 
    fg3m: Optional[int]
    fg3a: Optional[int]
    fg3_pct: Optional[float] 
    ftm: Optional[int]
    fta: Optional[int]
    ft_pct: Optional[float]  
    reb: Optional[int]
    ast: Optional[int]
    tov: Optional[int]
    stl: Optional[int]
    blk: Optional[int]
    pf: Optional[int]


def clean_player_names(group_name_raw: str) -> str:
    if not group_name_raw or not isinstance(group_name_raw, str):
        return None
    
    parts = group_name_raw.split(" - ")
    cleaned_names = []
    
    for name in parts:
        name = name.strip()
        if not name:
            continue
        
        if '. ' in name:
            last_name = name.split('. ', 1)[-1]
            cleaned_names.append(last_name)
        elif ' ' in name:
            last_name = name.split()[-1]
            cleaned_names.append(last_name)
        else:
            cleaned_names.append(name)
    
    return "; ".join(cleaned_names) if cleaned_names else None


def extract_lineups_for_date(
    game_date: str,
    season: str,
    team_id: int,
    group_quantity: int = 5
) -> List[GameLineupRow]:

    logger.debug(f"Fetching lineup data for date {game_date}, team {team_id}")

    endpoint = call_with_retries(
        lambda: leaguedashlineups.LeagueDashLineups(
            season=season,
            season_type_all_star='Regular Season',
            group_quantity=group_quantity,
            measure_type_detailed_defense='Base',
            per_mode_detailed='Totals',
            date_from_nullable=game_date,  
            date_to_nullable=game_date,    
            team_id_nullable=team_id     
        )
    )
    
    dfs = endpoint.get_data_frames()
    
    if not dfs or dfs[0].empty:
        logger.debug(f"No lineup data for {game_date}")
        return []
    
    df = dfs[0]
    
    df = df[df['TEAM_ID'] == team_id]
    
    if df.empty:
        logger.debug(f"No lineups for team {team_id} on {game_date}")
        return []
    
    logger.info(f"Found {len(df)} lineups for team {team_id} on {game_date}")
    
    lineup_rows = []
    
    for idx, row in df.iterrows():
        group_id = str(row.get('GROUP_ID', ''))
        if not group_id or group_id == 'nan':
            group_id = f"date_{game_date.replace('/', '')}_lineup_{idx}"
        
        group_name_raw = row.get('GROUP_NAME')
        group_name = clean_player_names(group_name_raw)
        
        lineup_row = GameLineupRow(
            game_id='',  
            game_date=game_date,
            season=season,
            team_id=team_id,
            group_quantity=group_quantity,
            
            group_id=group_id,
            group_name=group_name,
            
  
            opponent_team_id=None,
            is_home=None,
            
   
            min=parse_float(row.get('MIN')),
            plus_minus=parse_int(row.get('PLUS_MINUS')),
            
            pts=parse_int(row.get('PTS')),
            fgm=parse_int(row.get('FGM')),
            fga=parse_int(row.get('FGA')),
            fg_pct=parse_float(row.get('FG_PCT')),
            
            fg3m=parse_int(row.get('FG3M')),
            fg3a=parse_int(row.get('FG3A')),
            fg3_pct=parse_float(row.get('FG3_PCT')),
            
            ftm=parse_int(row.get('FTM')),
            fta=parse_int(row.get('FTA')),
            ft_pct=parse_float(row.get('FT_PCT')),
            
            reb=parse_int(row.get('REB')),
            ast=parse_int(row.get('AST')),
            tov=parse_int(row.get('TOV')),
            stl=parse_int(row.get('STL')),
            blk=parse_int(row.get('BLK')),
            pf=parse_int(row.get('PF')),
        )
        
        lineup_rows.append(lineup_row)
    
    return lineup_rows


def get_game_info_for_date(engine: Engine, game_date: str, team_id: int) -> Optional[dict]:

    try:
        date_obj = datetime.strptime(game_date, '%m/%d/%Y')
        sql_date = date_obj.strftime('%Y-%m-%d')
    except:
        logger.error(f"Invalid date format: {game_date}")
        return None
    
    query = text("""
        SELECT 
            game_id,
            game_date,
            home_team_id,
            away_team_id,
            CASE WHEN home_team_id = :team_id THEN TRUE ELSE FALSE END as is_home,
            CASE WHEN home_team_id = :team_id THEN away_team_id ELSE home_team_id END as opponent_id
        FROM nba.fact_games
        WHERE game_date = :game_date
          AND (home_team_id = :team_id OR away_team_id = :team_id)
        LIMIT 1
    """)
    
    with engine.connect() as conn:
        result = conn.execute(query, {
            "game_date": sql_date,
            "team_id": team_id
        }).fetchone()
    
    if result:
        return {
            "game_id": result[0],
            "is_home": result[4],
            "opponent_team_id": result[5]
        }
    else:
        return None


SQL_UPSERT_GAME_LINEUP = """
INSERT INTO nba.lineup_game_logs (
    game_id, season, team_id, group_quantity,
    group_id, group_name,
    opponent_team_id, is_home, game_date,
    min, plus_minus,
    pts, fgm, fga, fg_pct,
    fg3m, fg3a, fg3_pct,
    ftm, fta, ft_pct,
    reb, ast, tov, stl, blk, pf,
    last_updated_at
)
VALUES (
    :game_id, :season, :team_id, :group_quantity,
    :group_id, :group_name,
    :opponent_team_id, :is_home, :game_date,
    :min, :plus_minus,
    :pts, :fgm, :fga, :fg_pct,
    :fg3m, :fg3a, :fg3_pct,
    :ftm, :fta, :ft_pct,
    :reb, :ast, :tov, :stl, :blk, :pf,
    NOW()
)
ON CONFLICT (game_id, team_id, group_id) DO UPDATE SET
    group_name = EXCLUDED.group_name,
    opponent_team_id = EXCLUDED.opponent_team_id,
    is_home = EXCLUDED.is_home,
    game_date = EXCLUDED.game_date,
    min = EXCLUDED.min,
    plus_minus = EXCLUDED.plus_minus,
    pts = EXCLUDED.pts,
    fgm = EXCLUDED.fgm,
    fga = EXCLUDED.fga,
    fg_pct = EXCLUDED.fg_pct,
    fg3m = EXCLUDED.fg3m,
    fg3a = EXCLUDED.fg3a,
    fg3_pct = EXCLUDED.fg3_pct,
    ftm = EXCLUDED.ftm,
    fta = EXCLUDED.fta,
    ft_pct = EXCLUDED.ft_pct,
    reb = EXCLUDED.reb,
    ast = EXCLUDED.ast,
    tov = EXCLUDED.tov,
    stl = EXCLUDED.stl,
    blk = EXCLUDED.blk,
    pf = EXCLUDED.pf,
    last_updated_at = NOW();
"""


def load_season_game_lineups_for_team(
    engine: Engine,
    season: str,
    team_id: int,
    group_quantity: int = 5,
    limit: Optional[int] = None,
    sleep_seconds: float = 1.0
) -> int:
    
    logger.info(f"Loading game-by-game lineups for team {team_id}, season {season}")
    logger.info(f"Using date-based approach (DateFrom/DateTo)")
    

    query = text("""
        SELECT DISTINCT game_date
        FROM nba.fact_games
        WHERE (home_team_id = :team_id OR away_team_id = :team_id)
          AND season = :season
        ORDER BY game_date
    """)
    
    with engine.connect() as conn:
        game_dates = conn.execute(query, {
            "team_id": team_id,
            "season": season
        }).fetchall()
    

    date_list = []
    for row in game_dates:
        date_obj = row[0]  

        date_str = date_obj.strftime('%m/%d/%Y')
        date_list.append((date_str, date_obj))
    
    if limit:
        date_list = date_list[:limit]
    
    logger.info(f"Found {len(date_list)} game dates to process")
    
    total_loaded = 0
    success_count = 0
    fail_count = 0
    no_data_count = 0
    
    for i, (api_date, sql_date) in enumerate(date_list, 1):
        logger.info(f"[{i}/{len(date_list)}] Processing date {api_date}...")
        
        try:

            lineup_rows = extract_lineups_for_date(
                api_date, season, team_id, group_quantity
            )
            
            if not lineup_rows:
                logger.debug(f"  → No lineup data (future game or rest day)")
                no_data_count += 1
                time.sleep(sleep_seconds)
                continue
            
            game_info = get_game_info_for_date(engine, api_date, team_id)
            
            if not game_info:
                logger.warning(f"  → No game found in fact_games for {api_date}")
                no_data_count += 1
                time.sleep(sleep_seconds)
                continue
            

            for lineup in lineup_rows:
                lineup.game_id = game_info['game_id']
                lineup.opponent_team_id = game_info['opponent_team_id']
                lineup.is_home = game_info['is_home']
            

            loaded = 0
            with engine.begin() as conn:
                for lineup in lineup_rows:

                    sql_game_date = sql_date.strftime('%Y-%m-%d')
                    
                    conn.execute(text(SQL_UPSERT_GAME_LINEUP), {
                        "game_id": lineup.game_id,
                        "season": lineup.season,
                        "team_id": lineup.team_id,
                        "group_quantity": lineup.group_quantity,
                        "group_id": lineup.group_id,
                        "group_name": lineup.group_name,
                        "opponent_team_id": lineup.opponent_team_id,
                        "is_home": lineup.is_home,
                        "game_date": sql_game_date,
                        "min": lineup.min,
                        "plus_minus": lineup.plus_minus,
                        "pts": lineup.pts,
                        "fgm": lineup.fgm,
                        "fga": lineup.fga,
                        "fg_pct": lineup.fg_pct,
                        "fg3m": lineup.fg3m,
                        "fg3a": lineup.fg3a,
                        "fg3_pct": lineup.fg3_pct,
                        "ftm": lineup.ftm,
                        "fta": lineup.fta,
                        "ft_pct": lineup.ft_pct,
                        "reb": lineup.reb,
                        "ast": lineup.ast,
                        "tov": lineup.tov,
                        "stl": lineup.stl,
                        "blk": lineup.blk,
                        "pf": lineup.pf,
                    })
                    loaded += 1
            
            total_loaded += loaded
            success_count += 1
            
            logger.info(f"  → Loaded {loaded} lineups for game {game_info['game_id']}")
            
        except Exception as e:
            logger.error(f"  → Failed: {e}")
            fail_count += 1
        
        time.sleep(sleep_seconds)
    
    # Summary
    logger.info("")
    logger.info("=" * 80)
    logger.info(f"LOAD SUMMARY")
    logger.info("=" * 80)
    logger.info(f"Dates processed: {len(date_list)}")
    logger.info(f"  Success: {success_count}")
    logger.info(f"  No data: {no_data_count}")
    logger.info(f"  Failed: {fail_count}")
    logger.info(f"Total lineups loaded: {total_loaded}")
    logger.info("=" * 80)
    
    return total_loaded