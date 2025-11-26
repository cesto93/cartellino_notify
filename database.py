import sqlite3
from datetime import date
from typing import Dict, Optional

DB_FILE = "cartellino.db"


def get_db_connection():
    """Establishes a connection to the SQLite database."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Initializes the database and creates tables if they don't exist."""
    conn = get_db_connection()
    conn.execute(
        "CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)"
    )
    conn.execute(
        "CREATE TABLE IF NOT EXISTS chats (chat_id INTEGER PRIMARY KEY, name TEXT)"
    )
    conn.execute(
        "CREATE TABLE IF NOT EXISTS user_settings (chat_id INTEGER, key TEXT, value TEXT, date TEXT, PRIMARY KEY (chat_id, key, date))"
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


def store_chat(chat_id: int, name: str) -> None:
    """Stores a chat ID and its associated name in the database."""
    conn = get_db_connection()
    conn.execute(
        "INSERT OR REPLACE INTO chats (chat_id, name) VALUES (?, ?)", (chat_id, name)
    )
    conn.commit()
    conn.close()


def store_start_time(chat_id: int, start_time: str) -> None:
    """Stores the start time for the current day for a specific chat."""
    today = date.today().isoformat()
    conn = get_db_connection()
    conn.execute(
        "INSERT OR REPLACE INTO user_settings (chat_id, key, value, date) VALUES (?, ?, ?, ?)",
        (chat_id, "start_time", start_time, today),
    )
    conn.commit()
    conn.close()


def get_start_time(chat_id: int) -> Optional[str]:
    """Retrieves the start time for a specific chat if it was stored today."""
    today = date.today().isoformat()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT value FROM user_settings WHERE chat_id = ? AND key = ? AND date = ?",
        (chat_id, "start_time", today),
    )
    row = cursor.fetchone()
    conn.close()
    return row["value"] if row else None


def store_daily_setting(chat_id: int, key: str, value: str) -> None:
    """
    Stores a setting for a specific chat along with the current date, making it valid for the day.
    """
    today = date.today().isoformat()
    conn = get_db_connection()
    conn.execute(
        "INSERT OR REPLACE INTO user_settings (chat_id, key, value, date) VALUES (?, ?, ?, ?)",
        (chat_id, key, value, today),
    )
    conn.commit()
    conn.close()


def get_daily_setting(chat_id: int, key: str) -> Optional[str]:
    """
    Retrieves a daily setting for a specific chat if it was stored today; otherwise, returns None.
    """
    today = date.today().isoformat()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT value FROM user_settings WHERE chat_id = ? AND key = ? AND date = ?",
        (chat_id, key, today),
    )
    row = cursor.fetchone()
    conn.close()
    return row["value"] if row else None
