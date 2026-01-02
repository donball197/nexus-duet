#!/bin/bash
# Debian Auto-Pilot Watchdog
LOG_FILE="/root/nexus-duet/autopilot.log"

# Use the status script to check T1
STATUS=$(/root/nexus-duet/status_check.sh)

if echo "$STATUS" | grep -q "❌ T1 Infrastructure: OFFLINE"; then
    echo "$(date): 🚨 T1 Offline. Triggering Fusion Launch..." >> "$LOG_FILE"
    /root/nexus-duet/fusion_launch.sh &
else
    echo "$(date): ✅ System healthy." >> "$LOG_FILE"
fi
