import sqlite3
import os
# Since we run from backend/, the db is just "tasks.db" next to us
DB_PATH = "tasks.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute('''CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_type TEXT, prompt TEXT, response TEXT,
        status TEXT DEFAULT 'PENDING', screenshot BLOB,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )''')
    conn.commit(); conn.close()

def db_panic():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("DELETE FROM tasks WHERE screenshot IS NOT NULL")
    conn.commit(); conn.close()
