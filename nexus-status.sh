#!/bin/bash
# Nexus Singularity: Refined Session HUD

GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================${NC}"
echo -e "      NEXUS SINGULARITY: SESSION HUD      "
echo -e "${CYAN}==========================================${NC}"

# 1. Functional Component Status (Improved Detection)
check_proc() {
    # Match the specific script name while ignoring the 'grep' process itself
    PID=$(pgrep -f "$1" | head -n 1)
    if [ -n "$PID" ]; then
        echo -e "$2: ${GREEN}RUNNING${NC} (PID: $PID)"
    else
        echo -e "$2: ${RED}OFFLINE${NC}"
    fi
}

check_proc "nexus_singularity" "AI NODE (Server)     "
check_proc "nexus_health.sh"    "HEALTH SENTINEL      "
check_proc "thermal_throttle.sh" "THERMAL PROTECTION   "
check_proc "voice_alert.sh"     "SINGULARITY VOICE    "

echo -e "${CYAN}------------------------------------------${NC}"

# 2. Hardware Vitals
TEMP=$(termux-battery-status | jq -r '.temperature')
RAM=$(free -m | awk '/Mem:/ { print $3 "/" $2 "MB (" int($3/$2*100) "%)" }')
SWAP=$(free -m | awk '/Swap:/ { print $3 "/" $2 "MB" }')

echo -e "DEVICE TEMP : ${GREEN}${TEMP}°C${NC}"
echo -e "RAM USAGE   : ${GREEN}${RAM}${NC}"
echo -e "SWAP BUFFER : ${GREEN}${SWAP}${NC}"

# 3. Network Bridge (Bypassing /proc/net/dev restriction)
IP=$(ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
[ -z "$IP" ] && IP="127.0.0.1"
echo -e "NODE BRIDGE : ${CYAN}http://${IP}:8080${NC}"
echo -e "${CYAN}==========================================${NC}"
