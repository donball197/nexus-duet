#!/bin/bash
while true; do
    clear
    echo "🛰️ NEXUS SOVEREIGN HEALTH MONITOR"
    echo "================================"
    
    # Extract RAM data
    TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    USED=$(free -m | awk '/Mem:/ {print $3}')
    FREE=$(free -m | awk '/Mem:/ {print $4}')
    
    # Calculate Percentage
    PCT=$((USED * 100 / TOTAL))
    
    # Visual Bar
    BAR_SIZE=20
    FILLED=$((PCT * BAR_SIZE / 100))
    EMPTY=$((BAR_SIZE - FILLED))
    
    printf "RAM: ["
    for i in $(seq 1 $FILLED); do printf "#"; done
    for i in $(seq 1 $EMPTY); do printf "-"; done
    printf "] %d%% (%d MB Used / %d MB Free)\n" "$PCT" "$USED" "$FREE"
    
    # Add Thermal Check
    TEMP=$(termux-battery-status | grep temperature | awk '{print $2}' | sed 's/,//')
    echo "TEMP: $TEMP°C"
    
    if [ $FREE -lt 300 ]; then
        echo -e "\n⚠️  LOW MEMORY WARNING: System unstable!"
    fi
    
    sleep 2
done
