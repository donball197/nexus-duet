#!/bin/bash
# Athena Pulse: Scheduled DevOps Health & Cleanup
API_URL="http://localhost:8080/chat"
LOG_FILE="/home/donball197/athenafusionx/devops_history.log"

echo "[Sun Dec 28 05:15:51 PM EST 2025] --- RUNNING NIGHTLY DEVOPS CHECK ---" >> $LOG_FILE

# 1. Trigger the DevOps Agent via the backend
RESPONSE=$(curl -s -X POST $API_URL \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Run a full system status check and analyze the latest logs for errors.", "user_id": "DEVOPS_CHRON"}')

echo "Agent Report: $RESPONSE" >> $LOG_FILE

# 2. SELF-CLEANING: Prune unused Docker data
echo "[Sun Dec 28 05:15:51 PM EST 2025] --- STARTING SYSTEM CLEANUP ---" >> $LOG_FILE
docker system prune -f >> $LOG_FILE

# 3. LOG ROTATION: Keep the log small (last 1000 lines)
tail -n 1000 $LOG_FILE > $LOG_FILE.tmp && mv $LOG_FILE.tmp $LOG_FILE

echo "[Sun Dec 28 05:15:51 PM EST 2025] --- PULSE COMPLETE ---" >> $LOG_FILE
