import logging
import sys
from pathlib import Path
from typing import Optional
from datetime import datetime


class ColoredFormatter(logging.Formatter):
    """Custom formatter with color coding for console output."""

    # ANSI color codes
    COLORS = {
        'DEBUG': '\033[36m',     # Cyan
        'INFO': '\033[32m',      # Green
        'WARNING': '\033[33m',   # Yellow
        'ERROR': '\033[31m',     # Red
        'CRITICAL': '\033[35m',  # Magenta
    }
    RESET = '\033[0m'

    def format(self, record: logging.LogRecord) -> str:
        """Format log record with color."""
        record = logging.makeLogRecord(record.__dict__)
        if record.levelname in self.COLORS:
            record.levelname = f"{self.COLORS[record.levelname]}{record.levelname}{self.RESET}"
        return super().format(record)


def configure_logging(log_file: Optional[Path] = None, level: str = "INFO") -> None:
    """Set up console and file logging once, on the root logger.

    Call this only from entry scripts. Every other module just uses
    logging.getLogger(__name__), and its messages flow up to these handlers.
    """
    numeric_level = getattr(logging, level.upper(), logging.INFO)

    root = logging.getLogger()
    root.setLevel(numeric_level)
    for handler in list(root.handlers):
        root.removeHandler(handler)

    fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    datefmt = '%Y-%m-%d %H:%M:%S'

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(ColoredFormatter(fmt, datefmt=datefmt))
    root.addHandler(console_handler)

    if log_file:
        log_file.parent.mkdir(parents=True, exist_ok=True)
        file_handler = logging.FileHandler(log_file, encoding="utf-8")
        file_handler.setFormatter(logging.Formatter(fmt, datefmt=datefmt))
        root.addHandler(file_handler)

    # Keep library connection chatter out of DEBUG runs
    logging.getLogger("urllib3").setLevel(logging.WARNING)


def get_default_log_file(process_name: str) -> Path:

    today = datetime.now().strftime('%Y-%m-%d')
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    return log_dir / f"{process_name}_{today}.log"