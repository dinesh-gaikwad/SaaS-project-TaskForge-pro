import sqlite3
from pathlib import Path
from app.core.config import settings

BASE_DIR = Path(__file__).resolve().parents[2]
DB_PATH = BASE_DIR / settings.DATABASE_FILE

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn
