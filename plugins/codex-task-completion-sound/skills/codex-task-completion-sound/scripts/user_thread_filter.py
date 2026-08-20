from __future__ import annotations

import argparse
import os
import sqlite3
import sys
from pathlib import Path


USER_THREAD = 0
INVALID_INPUT = 2
NOT_USER_THREAD = 3
CLASSIFICATION_UNAVAILABLE = 4


def default_codex_home() -> Path:
    configured = os.environ.get("CODEX_HOME")
    return Path(configured).expanduser() if configured else Path.home() / ".codex"


def state_databases(codex_home: Path) -> list[Path]:
    candidates = [path for path in codex_home.glob("state_*.sqlite") if path.is_file()]
    return sorted(candidates, key=lambda path: path.stat().st_mtime, reverse=True)


def classify(database: Path, thread_id: str) -> int | None:
    connection: sqlite3.Connection | None = None
    try:
        connection = sqlite3.connect(
            f"file:{database.resolve().as_posix()}?mode=ro",
            uri=True,
            timeout=1.0,
        )
        columns = {
            row[1]
            for row in connection.execute("PRAGMA table_info(threads)").fetchall()
        }
        if "id" not in columns or "thread_source" not in columns:
            return None
        row = connection.execute(
            "SELECT thread_source FROM threads WHERE id = ? LIMIT 1",
            (thread_id,),
        ).fetchone()
    except (OSError, sqlite3.Error):
        return None
    finally:
        if connection is not None:
            connection.close()

    if row is None:
        return None
    return USER_THREAD if row[0] == "user" else NOT_USER_THREAD


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Return success only when a Codex thread is user-owned."
    )
    parser.add_argument("--thread-id", required=True)
    parser.add_argument("--codex-home", type=Path, default=default_codex_home())
    parser.add_argument("--explain", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    thread_id = args.thread_id.strip()
    if not thread_id:
        return INVALID_INPUT

    for database in state_databases(args.codex_home.expanduser()):
        result = classify(database, thread_id)
        if result is None:
            continue
        if args.explain:
            label = "user" if result == USER_THREAD else "internal"
            print(f"{label}\t{database}")
        return result

    if args.explain:
        print("unavailable")
    return CLASSIFICATION_UNAVAILABLE


if __name__ == "__main__":
    raise SystemExit(main())
