#!/bin/bash
# Nexus Singularity: Hardware Health Sentinel

# --- CONFIGURATION ---
THRESHOLD_TEMP=43.0    # Alert if battery temp > 43°C
THRESHOLD_RAM_PCT=90   # Alert if RAM usage > 90%
ALERT_PHONE="[YOUR_NUMBER]" # Replace with your alert number

# --- MONITORING LOGIC ---
CUR_TEMP=$(termux-battery-status | jq -r '.temperature')
CUR_RAM_PCT=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

echo ">> STATUS: Temp: $CUR_TEMP°C | RAM: ${CUR_RAM_PCT%.*}%"

# 1. Thermal Sentinel Check
if (( $(echo "$CUR_TEMP > $THRESHOLD_TEMP" | bc -l) )); then
    MSG="ALERT: Nexus Node Overheating! Temp: $CUR_TEMP°C. Throttling possible."
    termux-sms-send -n $ALERT_PHONE "$MSG"
    termux-notification --title "Nexus Thermal Alert" --content "$MSG" --priority high
fi

# 2. Memory Pressure Check
if (( $(echo "$CUR_RAM_PCT > $THRESHOLD_RAM_PCT" | bc -l) )); then
    MSG="ALERT: Nexus RAM Critical! Usage: ${CUR_RAM_PCT%.*}%. Node may crash."
    termux-sms-send -n $ALERT_PHONE "$MSG"
    termux-notification --title "Nexus RAM Alert" --content "$MSG" --priority high
fi
