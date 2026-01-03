#!/data/data/com.termux/files/usr/bin/bash
pkill -f "uvicorn"
pkill -f "python"
fuser -k 8000/tcp 2>/dev/null
rm -rf temp_media/*
# Clean DB via python one-liner since paths are tricky now
python3 -c "import sqlite3; c=sqlite3.connect('backend/tasks.db'); c.execute('DELETE FROM tasks WHERE screenshot IS NOT NULL'); c.commit()"
echo "🚨 PANIC EXECUTED."
