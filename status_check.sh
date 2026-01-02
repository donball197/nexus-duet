#!/bin/bash

# --- CONFIGURATION ---
DB_PATH="/root/nexus-duet/backend/tasks.db"
PORT=18080

echo "--- 🛰️ NEXUS DUET SYSTEM HEALTH ---"

# 1. Check Backend Port
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ T1 Infrastructure: ONLINE (Port $PORT)"
else
    echo "❌ T1 Infrastructure: OFFLINE"
fi

# 2. Check Database State
if [ -f "$DB_PATH" ]; then
    PENDING=$(sqlite3 "$DB_PATH" "SELECT count(*) FROM tasks WHERE attempts = 0;")
    STALLED=$(sqlite3 "$DB_PATH" "SELECT count(*) FROM tasks WHERE attempts > 0;")
    echo "✅ T2 Persistence: ACTIVE ($PENDING Pending, $STALLED Stalled)"
else
    echo "❌ T2 Persistence: DB NOT FOUND"
fi

# 3. Check Agent Processes
AGENT_PID=$(pgrep -f "rust-devops-agent")
if [ -z "$AGENT_PID" ]; then
    echo "❌ T3 Chaos Agent: NOT RUNNING"
else
    echo "✅ T3 Chaos Agent: RUNNING (PID: $AGENT_PID)"
fi

echo "----------------------------------"
