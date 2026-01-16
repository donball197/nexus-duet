#!/bin/bash
# The Courier bridges the gap between Hardware and the Web UI
while true; do
    # 1. Pull hardware data from the Motorola sensor
    BATT_DATA=$(termux-battery-status)
    TEMP=$(echo $BATT_DATA | jq .temperature)
    STATUS=$(echo $BATT_DATA | jq -r .status)
    HEALTH=$(echo $BATT_DATA | jq -r .health)
    
    # 2. Package it for the Neural Dashboard
    # We write to the JSON file that the index.html is already polling
    echo "{\"goal\": \"SENTINEL: ACTIVE | TEMP: $TEMP°C | STATUS: $STATUS | HEALTH: $HEALTH\"}" > ~/nexus_singularity/static/neural_goal.json
    
    # 3. Frequency: 5-second pulse
    sleep 5
done
