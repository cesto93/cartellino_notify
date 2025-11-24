import sqlite3
from typing import Dict, Optional

DB_FILE = "cartellino.db"


def get_db_connection():
    """Establishes a connection to the SQLite database."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Initializes the database and creates the settings table if it doesn't exist."""
    conn = get_db_connection()
    conn.execute(
        "CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)"
    )
    conn.commit()
    conn.close()


def store_setting(key: str, value: str) -> None:
    """Stores a setting in the database."""
    conn = get_db_connection()
    conn.execute(
        "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)", (key, value)
    )
    conn.commit()
    conn.close()


def get_setting(key: str) -> Optional[str]:
    """Retrieves a setting from the database."""
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT value FROM settings WHERE key = ?", (key,))
    row = cursor.fetchone()
    conn.close()
    return row["value"] if row else None


def get_all_settings() -> Dict[str, str]:
    """Retrieves all settings from the database."""
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT key, value FROM settings")
    rows = cursor.fetchall()
    conn.close()
    return {row["key"]: row["value"] for row in rows}
