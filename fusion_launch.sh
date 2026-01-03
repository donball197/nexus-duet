#!/bin/bash

# --- CONFIGURATION ---
DB_PATH="/data/data/com.termux/files/home/nexus-duet-native/backend/tasks.db"

# --- T2 PERSISTENCE CLEANUP ---
echo "🧹 Cleaning T2 Persistence locks..."
rm -f ~/nexus-duet-native/backend/db/*.db-journal
rm -f ~/nexus-duet-native/backend/*.db-journal

# --- T4 GATEWAY VERIFICATION ---
echo "📡 Verifying Port 18080 availability..."
if lsof -Pi :18080 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️ Port 18080 is busy. Killing old process..."
    fuser -k 18080/tcp
fi

# --- SELF-HEALING LOOP (Background) ---
(
    while true; do
        sleep 30
        # Check for tasks that have failed at least once but haven't hit the 5-cap
        STALLED_COUNT=$(sqlite3 "$DB_PATH" "SELECT count(*) FROM tasks WHERE attempts > 0 AND attempts < 5;")
        if [ "$STALLED_COUNT" -gt 0 ]; then
            echo "🩹 Self-Healer: Resetting $STALLED_COUNT stalled tasks..."
            sqlite3 "$DB_PATH" "UPDATE tasks SET attempts = 0 WHERE attempts > 0;"
        fi
    done
) &
HEALER_PID=$!

# --- T1 INFRASTRUCTURE LAUNCH ---
echo "🏛️ Launching T1 Infrastructure..."
cd ~/nexus-duet-native/backend
../target/release/athenafusionx-backend &
BACKEND_PID=$!

# --- T3 AGENT SYNCHRONIZATION ---
sleep 2
echo "🛡️ Launching T3 Chaos Agent (100% Logic)..."
cd ~/nexus-duet-native/agents
cargo run &
AGENT_PID=$!

echo "🚀 Nexus Duet T7 Fusion Active. Press Ctrl+C to shutdown."

# Handle graceful shutdown of all 3 processes
trap "kill $BACKEND_PID $AGENT_PID $HEALER_PID; echo '🛑 Shutdown complete.'; exit" INT
wait

