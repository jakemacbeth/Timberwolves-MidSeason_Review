"""
Weekly batch pipeline runner for Wolves Analytics.

Orchestrates the full ETL pipeline:
1. Load spine (game IDs for season)
2. Load game structure and team dimensions
3. Load team boxscores
4. Load player dimensions and boxscores
5. Load lineup data

"""
import sys
from datetime import datetime
from pathlib import Path

from config import get_config
from src.db.engine import get_engine
from src.etl.spine import load_seasons
from src.etl.load_factgames_dimteams import load_game_structure
from src.etl.load_team_boxscores import load_teambox_scores
from src.etl.load_dimplayers_boxscores import load_dimplayer_boxscores
from src.utils.logger import setup_logger, get_default_log_file
from src.etl.load_gamebygame_lineups import load_season_game_lineups_for_team


log_file = get_default_log_file("daily_run")
logger = setup_logger(__name__, log_file=log_file)


def get_current_season() -> str:

    config = get_config()
    
    # Check for environment variable override
    if config.current_season:
        logger.info(f"Using season from environment: {config.current_season}")
        return config.current_season
    

    now = datetime.now()
    year = now.year
    month = now.month
    
    # If before October, we're still in the previous season
    if month < 10:
        season = f"{year-1}-{str(year)[-2:]}"
    else:
        season = f"{year}-{str(year+1)[-2:]}"
    
    logger.info(f"Auto-detected current season: {season}")
    return season


def main() -> int:

    start_time = datetime.now()
    logger.info("=" * 80)
    logger.info("Starting Wolves Analytics Daily ETL Pipeline")
    logger.info("=" * 80)
    
    try:
        config = get_config()
        current_season = get_current_season()
        
        logger.info(f"Season: {current_season}")
        logger.info(f"Sleep between API calls: {config.etl.default_sleep_seconds}s")
        logger.info(f"Max retries: {config.etl.max_retries}")
        
        engine = get_engine()
        logger.info("Database engine initialized")
        
        # Update spine with new completed games
        logger.info("")
        logger.info("-" * 80)
        logger.info("Loading game spine")
        logger.info("-" * 80)
        load_seasons(current_season)
        

        logger.info("")
        logger.info("-" * 80)
        logger.info("Loading game structure and team dimensions")
        logger.info("-" * 80)
        load_game_structure(
            engine=engine,
            season=current_season,
            sleep_seconds=config.etl.default_sleep_seconds,
            limit=None
        )
        
        # Fill team boxscores for games missing teambox rows
        logger.info("")
        logger.info("-" * 80)
        logger.info("Loading team boxscores")
        logger.info("-" * 80)
        load_teambox_scores(
            engine=engine,
            season=current_season,
            sleep_seconds=config.etl.default_sleep_seconds,
            limit=None
        )
        
        # Fill player dimension + player boxscores for games missing playerbox rows
        logger.info("")
        logger.info("-" * 80)
        logger.info("Loading player dimensions and boxscores")
        logger.info("-" * 80)
        load_dimplayer_boxscores(
            engine=engine,
            season=current_season,
            sleep_seconds=config.etl.default_sleep_seconds,
            limit=None
        )

        logger.info("")
        logger.info("-" * 80)
        logger.info("Loading Timberwolves lineup data")
        logger.info("-" * 80)


        # Load in lineup specific stats 
          
        load_season_game_lineups_for_team(
            engine=engine,
            season="2025-26",
            team_id=1610612750,  # Timberwolves
            group_quantity=5,
            limit=None,  
            sleep_seconds=1.0
        )

        # Success summary
        duration = (datetime.now() - start_time).total_seconds()
        logger.info("")
        logger.info("=" * 80)
        logger.info("Daily ETL Pipeline Completed Successfully")
        logger.info(f"Total duration: {duration:.2f} seconds ({duration/60:.2f} minutes)")
        logger.info("=" * 80)
        
        return 0
        
    except KeyboardInterrupt:
        logger.warning("Pipeline interrupted by user")
        return 1
        
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        logger.error("")
        logger.error("=" * 80)
        logger.error("Daily ETL Pipeline FAILED")
        logger.error(f"Duration before failure: {duration:.2f} seconds")
        logger.error(f"Error: {e}")
        logger.error("=" * 80)
        logger.exception("Full traceback:")
        return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)