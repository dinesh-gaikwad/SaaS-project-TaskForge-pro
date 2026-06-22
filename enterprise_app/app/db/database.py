import sqlite3
from pathlib import Path
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

DB_PATH = "enterprise.db"

def get_connection() -> sqlite3.Connection:
    """Get a database connection with row factory."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA synchronous = NORMAL")
    return conn

def execute_query(query: str, params: tuple = (), fetch: str = None):
    """Execute a query and optionally fetch results."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(query, params)
        if fetch == "one":
            result = cur.fetchone()
        elif fetch == "all":
            result = cur.fetchall()
        else:
            conn.commit()
            result = cur.lastrowid
        return result
    except Exception as e:
        conn.rollback()
        logger.error(f"Database error: {e}")
        raise
    finally:
        conn.close()

def execute_many(query: str, params_list: list):
    """Execute multiple queries in a transaction."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.executemany(query, params_list)
        conn.commit()
        return cur.rowcount
    except Exception as e:
        conn.rollback()
        logger.error(f"Database error: {e}")
        raise
    finally:
        conn.close()

def table_exists(table_name: str) -> bool:
    """Check if a table exists in the database."""
    result = execute_query(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
        fetch="one"
    )
    return result is not None

def get_table_count(table_name: str) -> int:
    """Get total count of records in a table."""
    result = execute_query(f"SELECT COUNT(*) as cnt FROM {table_name}", fetch="one")
    return result["cnt"] if result else 0
