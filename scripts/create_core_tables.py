from pathlib import Path
from sqlalchemy import text
from src.db.engine import get_engine

SCHEMA_DIR = Path(__file__).resolve().parents[1] / "src" / "db" / "schema"

# Run in this order: later files reference tables created by earlier ones.
SCHEMA_FILES = [
    "create_spine_table.sql",
    "games_boxscores_tables.sql",
    "lineup_game_logs.sql",
    "error_tracking.sql",
]


def _read_sql(path: Path) -> str:
    if not path.exists():
        raise FileNotFoundError(f"Could not find schema file at: {path}")
    return path.read_text(encoding="utf-8")


def main() -> None:

    engine = get_engine()

    ddl_by_file = {name: _read_sql(SCHEMA_DIR / name) for name in SCHEMA_FILES}

    with engine.begin() as conn:
        for name, ddl in ddl_by_file.items():
            conn.execute(text(ddl))
            print(f"applied {name}")

    print("tables created (spine, core, lineups and etl_errors)")


if __name__ == "__main__":
    main()