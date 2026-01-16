#!/bin/bash

echo "🚀 INITIALIZING FULL NEXUS SOVEREIGNTY..."

# 1. Kill any zombie processes to ensure a clean start
pkill -f command_bridge.py
pkill -f thermal_courier.sh
pkill -f watcher_agent.py

# 2. Ignite the Executive Bridge (Web-to-Hardware)
nohup python ~/nexus_singularity/command_bridge.py > /dev/null 2>&1 &
echo ">> [1/4] EXECUTIVE BRIDGE: ONLINE"

# 3. Ignite the Thermal Courier (Hardware-to-Web)
nohup bash ~/nexus_singularity/thermal_courier.sh > /dev/null 2>&1 &
echo ">> [2/4] SENSORY COURIER: ONLINE"

# 4. Awakening the Brain (Watcher)
nohup python ~/nexus_singularity/watcher_agent.py > /dev/null 2>&1 &
echo ">> [3/4] NEURAL WATCHER: ONLINE"

# 5. Synchronizing the Pulse (Ledger)
TIMESTAMP=$(date)
echo "- System Cold Boot: $TIMESTAMP" >> ~/nexus_singularity/nexus_memory/LEDGER.md
echo ">> [4/4] STRATEGIC LEDGER: SYNCED"

# 6. Final Vocal & Haptic Handshake
termux-vibrate -d 200
termux-tts-speak "All systems sovereign. Infrastructure is hot."

echo "--------------------------------------"
echo "BOOT SEQUENCE COMPLETE. WORKSTATION READY."
