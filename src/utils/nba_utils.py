from __future__ import annotations
import logging
import time
from typing import Any, Callable, Optional

from config import ETLConfig

logger = logging.getLogger(__name__)


def call_with_retries(
    call_fn: Callable[[], Any],
    max_retries: Optional[int] = None,
    backoff_seconds: Optional[list[int]] = None,
    max_total_wait_seconds: Optional[int] = None,
) -> Any:
    """
    Retry NBA API calls with long backoff (throttle-friendly),
    but cap total time spent on a single call so backfills keep moving.

    Any setting not passed in comes from config.etl, so ETL_MAX_RETRIES
    in .env controls every loader at once.
    """
    etl = ETLConfig.from_env()
    if max_retries is None:
        max_retries = etl.max_retries
    if backoff_seconds is None:
        backoff_seconds = etl.retry_backoff_seconds
    if max_total_wait_seconds is None:
        max_total_wait_seconds = etl.max_total_wait_seconds  # cap at 10 minutes per call

    start = time.time()

    for attempt in range(max_retries):
        try:
            return call_fn()
        except Exception as e:
            if attempt == max_retries - 1:
                raise

            wait = backoff_seconds[min(attempt, len(backoff_seconds) - 1)]

            elapsed = time.time() - start
            if elapsed + wait > max_total_wait_seconds:
                raise

            logger.warning(
                f"API call failed ({type(e).__name__}: {e}). "
                f"Retrying in {wait}s (attempt {attempt + 1}/{max_retries})..."
            )
            time.sleep(wait)

    raise RuntimeError("Unexpected retry fallthrough")