#!/bin/bash
# Nexus Singularity: Context Switcher

CLIENT=$1
if [ -z "$CLIENT" ]; then
    echo "Usage: nexus-switch [client_name]"
    exit 1
fi

BASE_DIR="$HOME/nexus_singularity/portfolio/$CLIENT"

if [ ! -d "$BASE_DIR" ]; then
    echo ">> ERROR: Client '$CLIENT' does not exist in portfolio."
    exit 1
fi

echo ">> SWITCH: Transitioning to $CLIENT context..."

# Stop server, swap config, restart
pkill -f "nexus_singularity"
sleep 2

nohup ~/nexus_singularity/nexus_singularity --config "$BASE_DIR/config/specialist.yaml" > server.log 2>&1 &

echo ">> SUCCESS: Node is now serving $CLIENT vectors."
termux-tts-speak "Context switched to $CLIENT."
