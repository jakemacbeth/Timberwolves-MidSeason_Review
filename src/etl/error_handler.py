"""
Error tracking and handling for ETL pipeline.
Provides structured error logging to database for monitoring,
debugging and retry.
"""
import traceback
from typing import Optional
from sqlalchemy import text
from sqlalchemy.engine import Engine

from src.utils.logger import setup_logger

logger = setup_logger(__name__)


def log_etl_error(
    engine: Engine,
    process_name: str,
    error: Exception,
    game_id: Optional[str] = None,
    retry_count: int = 0,
) -> None:

    error_sql = text("""
        INSERT INTO nba.etl_errors (
            process_name, game_id, error_type, 
            error_message, stack_trace, retry_count
        )
        VALUES (
            :process_name, :game_id, :error_type,
            :error_message, :stack_trace, :retry_count
        )
    """)
    
    try:
        with engine.begin() as conn:
            conn.execute(error_sql, {
                "process_name": process_name,
                "game_id": game_id,
                "error_type": type(error).__name__,
                "error_message": str(error),
                "stack_trace": "".join(traceback.format_exception(error)),
                "retry_count": retry_count,
            })
        logger.debug(f"Logged error to database: {process_name} - {game_id}")
    except Exception as db_error:
        # If we can't log to DB, at least log to console
        logger.error(f"Failed to log error to database: {db_error}")
        logger.error(f"Original error: {error}")


def mark_error_resolved(
    engine: Engine,
    process_name: str,
    game_id: str,
) -> int:

    resolve_sql = text("""
        UPDATE nba.etl_errors
        SET is_resolved = TRUE,
            resolved_at = NOW()
        WHERE process_name = :process_name
          AND game_id = :game_id
          AND is_resolved = FALSE
    """)
    
    with engine.begin() as conn:
        result = conn.execute(resolve_sql, {
            "process_name": process_name,
            "game_id": game_id,
        })
        count = result.rowcount
    
    if count > 0:
        logger.info(f"Marked {count} error(s) as resolved: {process_name} - {game_id}")
    
    return count


def get_failed_game_ids(
    engine: Engine,
    process_name: str,
    limit: Optional[int] = None,
) -> list[str]:

    query = text("""
        SELECT game_id
        FROM nba.etl_errors
        WHERE process_name = :process_name
          AND is_resolved = FALSE
          AND game_id IS NOT NULL
        GROUP BY game_id
        ORDER BY MAX(created_at) DESC
        LIMIT :limit
    """)
    
    with engine.connect() as conn:
        result = conn.execute(query, {
            "process_name": process_name,
            "limit": limit or 1000,
        })
        game_ids = [row[0] for row in result]
    
    return game_ids


def get_error_summary(engine: Engine, days: int = 7) -> dict:

    window = "created_at >= NOW() - make_interval(days => :days)"

    totals_sql = text(f"""
        SELECT
            COUNT(*) AS total_errors,
            COUNT(*) FILTER (WHERE is_resolved = FALSE) AS unresolved
        FROM nba.etl_errors
        WHERE {window}
    """)

    by_process_sql = text(f"""
        SELECT process_name, COUNT(*) AS error_count
        FROM nba.etl_errors
        WHERE {window}
        GROUP BY process_name
        ORDER BY error_count DESC
    """)

    by_type_sql = text(f"""
        SELECT error_type, COUNT(*) AS error_count
        FROM nba.etl_errors
        WHERE {window}
        GROUP BY error_type
        ORDER BY error_count DESC
    """)

    params = {"days": days}

    with engine.connect() as conn:
        totals = conn.execute(totals_sql, params).fetchone()
        by_process = {row[0]: row[1] for row in conn.execute(by_process_sql, params)}
        by_type = {row[0]: row[1] for row in conn.execute(by_type_sql, params)}

    return {
        "total_errors": totals[0],
        "unresolved": totals[1],
        "by_process": by_process,
        "by_type": by_type,
    }