#!/bin/bash
# Nexus Singularity: Thermal Sentinel

LIMIT=42
echo ">> SENTINEL: Thermal monitoring active (Limit: ${LIMIT}°C)..."

while true; do
    # Get temperature and strip decimals for Bash comparison
    RAW_TEMP=$(termux-battery-status | jq -r '.temperature')
    TEMP=${RAW_TEMP%.*}  # Converts "36.0" to "36"

    echo -ne ">> CURRENT TEMP: ${RAW_TEMP}°C \r"

    if [ "$TEMP" -ge "$LIMIT" ]; then
        echo -e "\n\033[1;31m>> WARNING: TEMP CRITICAL (${RAW_TEMP}°C). PAUSING BUILD...\033[0m"
        termux-notification --title "Thermal Alert" --content "Heat Limit Reached: Pausing Build."
        pkill -STOP rustc
        
        while [ "$TEMP" -ge 38 ]; do
            sleep 30
            RAW_TEMP=$(termux-battery-status | jq -r '.temperature')
            TEMP=${RAW_TEMP%.*}
            echo -ne ">> COOLING: ${RAW_TEMP}°C \r"
        done
        
        echo -e "\n\033[1;32m>> SAFE: RESUMING BUILD...\033[0m"
        pkill -CONT rustc
    fi
    sleep 10
done
