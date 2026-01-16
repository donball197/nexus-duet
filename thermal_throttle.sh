#!/bin/bash
# Nexus Singularity: Automated Thermal Throttling

THRESHOLD_THROTTLE=43.0
NODE_NAME="nexus_singularity"

echo ">> THERMAL: Monitoring $NODE_NAME for heat protection..."

while true; do
    CUR_TEMP=$(termux-battery-status | jq -r '.temperature')
    PID=$(pgrep -f "$NODE_NAME")

    if (( $(echo "$CUR_TEMP > $THRESHOLD_THROTTLE" | bc -l) )); then
        if [ -n "$PID" ]; then
            echo ">> CRITICAL: Temp $CUR_TEMP°C. Throttling $NODE_NAME (PID: $PID)..."
            renice -n 19 -p $PID
            termux-notification --title "Thermal Throttle" --content "Node priority lowered to COOLING MODE."
        fi
    else
        if [ -n "$PID" ]; then
            # Restore to standard priority if temperature is safe
            renice -n 0 -p $PID
        fi
    fi
    sleep 60
done
